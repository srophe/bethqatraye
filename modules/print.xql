xquery version "3.1";

import module namespace config="http://syriaca.org/srophe/config" at "config.xqm";
import module namespace global="http://syriaca.org/srophe/global" at "lib/global.xqm";
import module namespace tei2html="http://syriaca.org/srophe/tei2html" at "content-negotiation/tei2html.xqm";
import module namespace bibl2html="http://syriaca.org/srophe/bibl2html" at "bibl2html.xqm";

declare namespace http="http://expath.org/ns/http-client";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace srophe="https://srophe.app";
declare namespace html="http://www.w3.org/1999/xhtml";

declare variable $local:start {request:get-parameter('start', 1) cast as xs:integer};
declare variable $local:perpage {request:get-parameter('perpage', 25) cast as xs:integer};

declare function local:record($r){
let $title := tei2html:rec-headwords($r) 
let $idNo := tokenize(replace($r/tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:idno,'/tei',''),'/')[last()]
let $author := bibl2html:emit-responsible-persons($r/descendant::tei:titleStmt/tei:editor[@role='creator'],3)
let $bibls := <bibliography xmlns="http://www.tei-c.org/ns/1.0">{$r/descendant::tei:place/tei:bibl}</bibliography>
return     
 <div xmlns="http://www.w3.org/1999/xhtml">
    <h2 style="text-align:center;">{$title}</h2>
    {
        for $desc in $r/descendant::tei:place/tei:desc
        return 
            <div>{global:tei2html($desc)}</div>
    }
    <p><em>Type of Location: </em>{string($r/descendant::tei:place/@type)}</p>
    <p><em>Bibliography:</em></p>
    <div style="margin-left:1em;">{global:tei2html($bibls)}</div>
    <p><em>Name Variants: </em>
    {
        string-join(for $name in $r/descendant::tei:place/tei:placeName
        return $name,', ') 
     }</p>
     <p><em>Online Resources: </em></p>
     <ul>
        <li>{$r/descendant::tei:place/tei:idno[1]/text()}</li>
        <li>{$r/descendant::tei:place/tei:idno[2]/text()}</li>
     </ul>
     <p><em>Author: </em> {$author}</p>
     <hr/>
 </div>
};

declare function local:get-records(){
let $results := collection($config:data-root)//tei:TEI
let $start := if($local:start) then $local:start else 0
let $perpage := if(request:get-parameter('perpage', '') != '') then $local:perpage else count($results)
return 
<html xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <title>Print {$config:app-title}</title>
        <link rel="stylesheet" type="text/css" href="$nav-base/resources/bootstrap/css/bootstrap.min.css"/>
        <link rel="stylesheet" type="text/css" href="$nav-base/resources/css/syr-icon-fonts.css"/>
        <link rel="stylesheet" type="text/css" href="$nav-base/resources/css/style.css"/>
    </head>
    <body style="background-color:white; margin:1em;">
        {
        for $r in subsequence($results,$start,$start + $perpage)
        return local:record($r)
         }
     </body>
     </html>
};

local:get-records()