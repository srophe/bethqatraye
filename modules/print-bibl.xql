xquery version "3.1";

import module namespace config="http://syriaca.org/srophe/config" at "config.xqm";
import module namespace global="http://syriaca.org/srophe/global" at "lib/global.xqm";
import module namespace tei2html="http://syriaca.org/srophe/tei2html" at "content-negotiation/tei2html.xqm";
import module namespace bibl2html="http://syriaca.org/srophe/bibl2html" at "bibl2html.xqm";

declare namespace http="http://expath.org/ns/http-client";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace srophe="https://srophe.app";
declare namespace html="http://www.w3.org/1999/xhtml";

declare variable $local:uri {request:get-parameter('uri', '')};
declare variable $local:start {request:get-parameter('start', 1) cast as xs:integer};
declare variable $local:perpage {request:get-parameter('perpage', 25) cast as xs:integer};


declare function local:display-bibls(){
<html xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <title>Print {$config:app-title}</title>
        <link rel="stylesheet" type="text/css" href="$nav-base/resources/bootstrap/css/bootstrap.min.css"/>
        <link rel="stylesheet" type="text/css" href="$nav-base/resources/css/syr-icon-fonts.css"/>
        <link rel="stylesheet" type="text/css" href="$nav-base/resources/css/style.css"/>
        <style>
        <![CDATA[
            body {color: black;}
            .footnote-links {display:none;}
            a {color: black;}
        ]]>
        </style>
    </head>
    <body style="background-color:white; margin:1em;">
    <h1>{$config:app-title} Selected Bibliography</h1>
        {
        for $rec in tokenize($local:uri,' ')
        let $tei := http:send-request(<http:request http-version="1.1" href="{xs:anyURI(concat($rec,'/tei'))}" method="get"><http:header name="Connection" value="close"/></http:request>)[2]
        return <p>{global:tei2html(<preferredCitation xmlns="http://www.tei-c.org/ns/1.0">{$tei/descendant::tei:biblStruct}</preferredCitation>)}</p>
        }
     </body>
</html>
};

if($local:uri != '') then
    local:display-bibls()
else 
    <div>No URIs submitted. Expected format @uri=http://syriaca.org/bibl/1110 http://syriaca.org/bibl/1111 http://syriaca.org/bibl/4</div>