procedure fitsexist( ndf, keyword )
begin
 string tndf=""
 string gndf
 string tkeyword=""
 string gkeyword
 gndf = str(ndf)
 if ( gndf != "" ) tndf = "ndf=" + gndf + " "
 ;
 gkeyword = str(keyword)
 if ( gkeyword != "" ) tkeyword = "keyword=\"" + gkeyword + "\" "
 ;
 print ("fitsmod ",tndf,tkeyword,"edit=exist ","mode_=interface ") | cl
end
