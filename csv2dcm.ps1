import-module $PSScriptRoot\Dicom.Cmdlet
$conf = Read-Properties $PSScriptRoot\csv2dcm.properties

$dirtmp =  ($PSScriptRoot +"\tmp\")
$templatefile = ($PSScriptRoot +"\template.dotx")
$outdir = ($PSScriptRoot +"\out\")
$studies = Import-CSV $conf.csvfile -Delimiter ";"
$json2docx = ($PSScriptRoot +"\bin\json2docx.exe")
if (!(Test-Path $dirtmp))
	{
		New-Item -ItemType directory -Path $dirtmp
	}
if (!(Test-Path $outdir)) {
	New-Item -ItemType directory -Path $outdir
}
foreach ($study in $studies) {
 
	$fileroot=$dirtmp + $study.studyInstanceUID
	$birthdate = $study.birthDate;
 
	$studyDate = $study.StudyDate;
	$study.birthDate = (New-TimeSpan -Start (Get-Date "01/01/1970" ) -End (Get-Date $study.birthDate)).TotalSeconds * 1000;
	$study.studyDate = (New-TimeSpan -Start (Get-Date "01/01/1970") -End (Get-Date  $study.studyDate)).TotalSeconds * 1000;
	ConvertTo-Json -InputObject $study | Out-File -filepath ($fileroot + ".json") -Encoding ascii
	#Write-Host ("C:\workspace\json2docx\bin\json2docx -t " + $templatefile  + " -j " + ($fileroot + ".json") +" -d " + ($fileroot + ".docx") + " -e png")
	&$json2docx  -t $templatefile -j ($fileroot + ".json") -d ($fileroot + ".docx") -e png
	ConvertTO-Dicom ($fileroot + ".png") ($fileroot + ".dcm")
	import-dicom  ($fileroot + ".dcm") | 
	edit-dicom -Tag "0010,0020" -Value $study.patientId |
	edit-dicom -Tag "0010,0010"  -Value ($study.lastName +"^" + $study.firstName)|
	edit-dicom -Tag "0010,0040" -Value $study.sex |
	edit-dicom -Tag "0010,0030" -Value (get-Date $birthdate  -Format 'yyyyMMdd')  |
	edit-dicom -Tag "0008,0060" -Value $study.modalitiesInStudy |
	edit-dicom -Tag "0008,0061" -Value $study.modalitiesInStudy |
	edit-dicom -Tag "0008,0050" -Value $study.AccessionNumber |
	edit-dicom -Tag "0008,0020" -Value (get-Date  $studyDate -Format 'yyyyMMdd')  |
	edit-dicom -Tag "0020,0010" -Value $study.AccessionNumber |
	edit-dicom -Tag "0020,000D" -Value $study.studyInstanceUID  |
	edit-dicom  -Tag "0020,000E" -Value ($study.studyInstanceUID + ".1.0.1")  |
	edit-dicom  -Tag "0008,0018" -Value ($study.studyInstanceUID + ".1.0.2") |
	save-dicom -FileName ($outdir+$study.studyInstanceUID +".dcm")
}

