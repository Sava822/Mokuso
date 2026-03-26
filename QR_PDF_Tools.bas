Attribute VB_Name = "QR_PDF_Tools"
'=============================================================
'  MODULE: QR_PDF_Tools
'  QUOT sheet - Generate QR code + Save password-protected PDF
'
'  Button on Q4 -> assign to: QR_And_SavePDF
'
'  QR source:   M2 (mailto formula)
'  QR position: M4, fixed 171x171 pt, free-floating
'  PDF name:    A2 (dynamic Quotation-ID)
'  PDF password: zenner + YYYYMMDD
'  Print area:  A1:O71
'=============================================================


'-------------------------------------------------------------
' ENTRY POINT - button calls this
'-------------------------------------------------------------
Sub QR_And_SavePDF()
    Dim bQR As Boolean
    bQR = GenerateQRCode()
    If bQR Then
        SaveQuotationAsPDF
    Else
        If MsgBox("QR code failed. Save PDF anyway?", _
                   vbYesNo + vbQuestion, "Continue?") = vbYes Then
            SaveQuotationAsPDF
        End If
    End If
End Sub


'-------------------------------------------------------------
' 1. QR CODE GENERATOR
'    Reads M2, fetches PNG via DownloadQR, inserts at M4
'    Returns True on success
'-------------------------------------------------------------
Function GenerateQRCode() As Boolean

    Dim ws          As Worksheet
    Dim sData       As String
    Dim sEncoded    As String
    Dim sURL        As String
    Dim sTempFile   As String
    Dim oShape      As Shape
    Dim rAnchor     As Range

    GenerateQRCode = False
    Set ws = ThisWorkbook.Sheets("QUOT")

    ' Read mailto string
    sData = Trim(ws.Range("M2").Value)
    If sData = "" Then
        MsgBox "Cell M2 is empty.", vbExclamation
        Exit Function
    End If

    ' URL-encode the data
    sEncoded = URLEncode(sData)

    ' Build full QR API URL
    sURL = "https://api.qrserver.com/v1/create-qr-code/?size=400x400&format=png&ecc=M&data=" & sEncoded

    ' Output file path (use workbook folder on Mac for sandbox safety)
    #If Mac Then
        sTempFile = ThisWorkbook.Path & "/qrcode_quot.png"
    #Else
        sTempFile = Environ("TEMP") & "\qrcode_quot.png"
    #End If

    ' Download QR image
    If Not DownloadQR(sURL, sTempFile) Then
        MsgBox "QR download failed. Check internet connection.", vbExclamation
        Exit Function
    End If

    ' Remove previous QR shape
    For Each oShape In ws.Shapes
        If oShape.Name = "QR_QUOT" Then oShape.Delete: Exit For
    Next oShape

    ' Insert at M4, fixed 171x171 pt, free-floating
    Set rAnchor = ws.Range("M4")
    With ws.Shapes.AddPicture( _
            FileName:=sTempFile, _
            LinkToFile:=msoFalse, _
            SaveWithDocument:=msoCTrue, _
            Left:=rAnchor.Left, _
            Top:=rAnchor.Top, _
            Width:=171, _
            Height:=171)
        .Name = "QR_QUOT"
        .Placement = xlFreeFloating
        .LockAspectRatio = msoTrue
    End With

    ' Clean up temp image
    On Error Resume Next: Kill sTempFile: On Error GoTo 0

    GenerateQRCode = True

End Function


'-------------------------------------------------------------
' 2. SAVE PASSWORD-PROTECTED PDF
'    Name from A2, password = zenner + YYYYMMDD
'    Encrypts with qpdf via bash -c (sandbox-safe)
'-------------------------------------------------------------
Sub SaveQuotationAsPDF()

    Dim ws          As Worksheet
    Dim sName       As String
    Dim sFolder     As String
    Dim sPDFPath    As String
    Dim sTempPDF    As String
    Dim sPassword   As String
    Dim qpdfPath    As String
    Dim dStart      As Double

    Const FLAG_PATH   As String = "/tmp/qpdf_done.flag"
    Const TIMEOUT_SEC As Long = 15

    Set ws = ThisWorkbook.Sheets("QUOT")

    ' --- Filename from A2 ---
    sName = Trim(ws.Range("A2").Value)
    If sName = "" Then
        MsgBox "Cell A2 is empty.", vbExclamation: Exit Sub
    End If
    sName = SanitiseFileName(sName)

    ' --- Workbook folder ---
    sFolder = ThisWorkbook.Path
    If sFolder = "" Then
        MsgBox "Save the workbook first.", vbExclamation: Exit Sub
    End If

    ' --- Paths ---
    sPDFPath = sFolder & "/" & sName & ".pdf"
    sTempPDF = sFolder & "/" & sName & "_TEMP.pdf"

    ' --- Password: zenner + YYYYMMDD ---
    sPassword = "zenner" & Format(Now, "YYYYMMDD")

    ' --- Clean up old files ---
    On Error Resume Next
    Kill sPDFPath
    Kill sTempPDF
    On Error GoTo 0
    Shell "bash -c 'rm -f " & FLAG_PATH & "'"
    WaitMs 300

    ' === STEP 1: Export unprotected PDF ===
    On Error GoTo ExportErr
    ws.ExportAsFixedFormat _
        Type:=xlTypePDF, _
        FileName:=sTempPDF, _
        Quality:=xlQualityStandard, _
        IncludeDocProperties:=True, _
        IgnorePrintAreas:=False, _
        OpenAfterPublish:=False
    On Error GoTo 0

    If Dir(sTempPDF) = "" Then
        MsgBox "Temp PDF not created. Check print area.", vbCritical
        Exit Sub
    End If

    ' === STEP 2: Locate qpdf ===
    #If Mac Then

        qpdfPath = FindQpdf()
        If qpdfPath = "" Then GoTo FallbackNoPW

        ' === STEP 3: Run qpdf via bash -c ===
        Dim sCmd As String
        sCmd = "'" & qpdfPath & "'" & _
               " --encrypt '" & sPassword & "' '" & sPassword & "' 256" & _
               " -- '" & sTempPDF & "' '" & sPDFPath & "'" & _
               " ; echo $? > '" & FLAG_PATH & "'"

        Shell "bash -c " & Chr(34) & sCmd & Chr(34)

        ' === STEP 4: Poll for flag file ===
        dStart = Timer
        Do While Dir(FLAG_PATH) = ""
            DoEvents
            If Timer - dStart > TIMEOUT_SEC Then
                MsgBox "Timeout - qpdf did not finish.", vbCritical
                GoTo Cleanup
            End If
            If Timer < dStart Then dStart = Timer
        Loop
        WaitMs 500

        ' === STEP 5: Read exit code ===
        Dim sExitCode As String
        Dim iFile As Integer
        iFile = FreeFile
        On Error GoTo ReadFlagErr
        Open FLAG_PATH For Input As #iFile
            Line Input #iFile, sExitCode
        Close #iFile
        On Error GoTo 0

        ' === STEP 6: Verify & report ===
        If Trim(sExitCode) = "0" And Dir(sPDFPath) <> "" And FileLen(sPDFPath) > 100 Then

            On Error Resume Next
            Kill sTempPDF
            On Error GoTo 0
            Shell "bash -c 'rm -f " & FLAG_PATH & "'"

            MsgBox "PDF saved & protected!" & vbNewLine & vbNewLine & _
                   "File:     " & sName & ".pdf" & vbNewLine & _
                   "Password: " & sPassword & vbNewLine & vbNewLine & _
                   "Folder:   " & sFolder, _
                   vbInformation, "Done"
        Else
            On Error Resume Next
            If Dir(sPDFPath) = "" Then FileCopy sTempPDF, sPDFPath
            Kill sTempPDF
            On Error GoTo 0
            MsgBox "qpdf exit code: " & sExitCode & vbNewLine & _
                   "PDF saved WITHOUT password.", vbExclamation
            GoTo Cleanup
        End If

    #Else
        GoTo FallbackNoPW
    #End If

    Exit Sub

FallbackNoPW:
    On Error Resume Next
    FileCopy sTempPDF, sPDFPath
    Kill sTempPDF
    On Error GoTo 0
    #If Mac Then
        MsgBox "qpdf not found - PDF saved WITHOUT password." & vbNewLine & _
               "Install: brew install qpdf", vbExclamation
    #Else
        MsgBox "PDF saved (no encryption):" & vbNewLine & sPDFPath, vbInformation
    #End If
    Exit Sub

ExportErr:
    MsgBox "PDF export error: " & Err.Description, vbCritical
    Exit Sub

ReadFlagErr:
    sExitCode = "READ_ERROR"
    Resume Next

Cleanup:
    On Error Resume Next
    Kill sTempPDF
    On Error GoTo 0
    Shell "bash -c 'rm -f " & FLAG_PATH & "'"

End Sub


'=============================================================
'  HELPER FUNCTIONS
'=============================================================


'-------------------------------------------------------------
' Download QR image
' Mac:     Uses Python urllib (reliable, no URL mangling)
' Windows: Uses MSXML2 + ADODB.Stream
'
' Includes proper timeouts to prevent hanging connections
' that make the network appear dead.
'-------------------------------------------------------------
Function DownloadQR(sURL As String, sOutPath As String) As Boolean

    DownloadQR = False

    ' Delete old output
    On Error Resume Next: Kill sOutPath: On Error GoTo 0

    #If Mac Then

        ' Use a flag file to know when the download is truly finished
        Dim sFlagPath As String
        sFlagPath = ThisWorkbook.Path & "/qr_dl_done.flag"
        On Error Resume Next: Kill sFlagPath: On Error GoTo 0

        ' Convert URL to hex so it passes cleanly through Shell
        ' (avoids %, &, ? mangling by VBA Shell)
        Dim sHex As String
        sHex = StringToHex(sURL)

        ' Python one-liner with 15-second timeout:
        '   - Decodes hex back to URL string
        '   - Downloads with timeout via urlopen
        '   - Writes a flag file on completion so VBA can poll
        Dim sCmd As String
        sCmd = "/usr/bin/python3 -c " & Chr(39) & _
               "import urllib.request,socket;" & _
               "socket.setdefaulttimeout(15);" & _
               "u=bytes.fromhex(" & Chr(34) & sHex & Chr(34) & ").decode();" & _
               "urllib.request.urlretrieve(u," & Chr(34) & sOutPath & Chr(34) & ");" & _
               "open(" & Chr(34) & sFlagPath & Chr(34) & ",'w').write('OK')" & _
               Chr(39)

        Shell "bash -c " & Chr(34) & sCmd & Chr(34)

        ' Poll for flag file instead of blind wait (max 20 seconds)
        Dim dStart As Double
        dStart = Timer
        Do While Dir(sFlagPath) = ""
            DoEvents
            If Timer - dStart > 20 Then Exit Do
            If Timer < dStart Then dStart = Timer   ' midnight rollover
        Loop
        WaitMs 300  ' brief settle time after flag appears

        ' Verify download succeeded
        If Dir(sOutPath) <> "" Then
            If FileLen(sOutPath) > 100 Then DownloadQR = True
        End If

        ' Clean up flag file
        On Error Resume Next: Kill sFlagPath: On Error GoTo 0

    #Else

        Dim oHTTP As Object, oStream As Object
        On Error GoTo DlErr
        Set oHTTP = CreateObject("MSXML2.ServerXMLHTTP.6.0")
        oHTTP.setTimeouts 5000, 5000, 10000, 10000
        oHTTP.Open "GET", sURL, False
        oHTTP.Send
        If oHTTP.Status = 200 Then
            Set oStream = CreateObject("ADODB.Stream")
            oStream.Open: oStream.Type = 1
            oStream.Write oHTTP.responseBody
            oStream.SaveToFile sOutPath, 2
            oStream.Close
            DownloadQR = True
        End If
DlErr:

    #End If

End Function


'-------------------------------------------------------------
' Locate qpdf on Mac
'-------------------------------------------------------------
Function FindQpdf() As String
    FindQpdf = ""
    Dim sPaths As Variant, p As Variant
    sPaths = Array("/opt/homebrew/bin/qpdf", _
                   "/usr/local/bin/qpdf", _
                   "/usr/bin/qpdf")
    For Each p In sPaths
        If Dir(CStr(p)) <> "" Then
            FindQpdf = CStr(p): Exit Function
        End If
    Next p
End Function


'-------------------------------------------------------------
' Sanitise string for file name
'-------------------------------------------------------------
Function SanitiseFileName(s As String) As String
    Dim aInvalid As Variant, v As Variant
    aInvalid = Array("/", "\", ":", "*", "?", """", "<", ">", "|")
    Dim sOut As String: sOut = s
    For Each v In aInvalid
        sOut = Replace(sOut, CStr(v), "-")
    Next v
    Do While Len(sOut) > 0 And (Left(sOut, 1) = "." Or Left(sOut, 1) = " ")
        sOut = Mid(sOut, 2)
    Loop
    Do While Len(sOut) > 0 And (Right(sOut, 1) = "." Or Right(sOut, 1) = " ")
        sOut = Left(sOut, Len(sOut) - 1)
    Loop
    If Len(sOut) > 200 Then sOut = Left(sOut, 200)
    SanitiseFileName = sOut
End Function


'-------------------------------------------------------------
' URL Encoder (Mac + Windows compatible)
'-------------------------------------------------------------
Function URLEncode(sText As String) As String
    Dim i    As Long
    Dim sOut As String
    Dim bVal As Long
    For i = 1 To Len(sText)
        bVal = Asc(Mid(sText, i, 1))
        Select Case bVal
            Case 48 To 57, 65 To 90, 97 To 122
                sOut = sOut & Chr(bVal)
            Case 45, 46, 95, 126
                sOut = sOut & Chr(bVal)
            Case Else
                sOut = sOut & "%" & Right("0" & Hex(bVal), 2)
        End Select
    Next i
    URLEncode = sOut
End Function


'-------------------------------------------------------------
' String to Hex (makes any string safe for Shell)
'-------------------------------------------------------------
Function StringToHex(s As String) As String
    Dim i As Long
    Dim sOut As String
    For i = 1 To Len(s)
        sOut = sOut & Right("0" & Hex(Asc(Mid(s, i, 1))), 2)
    Next i
    StringToHex = LCase(sOut)
End Function


'-------------------------------------------------------------
' Wait with DoEvents (ms)
'-------------------------------------------------------------
Sub WaitMs(ms As Long)
    Dim t As Single: t = Timer
    Do While (Timer - t) * 1000 < ms
        DoEvents
        If Timer < t Then t = Timer
    Loop
End Sub
