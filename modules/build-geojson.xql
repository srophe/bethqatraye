xquery version "3.1";
(:~  
 : Build GeoJSON file for all placeNames/@key  
 : NOTE: Save file to DB, rerun occasionally? When new data is added? 
 : Run on webhook activation, add new names, check for dups. 
:)

import module namespace config="http://syriaca.org/srophe/config" at "config.xqm";
import module namespace tei2html="http://syriaca.org/srophe/tei2html" at "content-negotiation/tei2html.xqm";
import module namespace http="http://expath.org/ns/http-client";

import module namespace functx="http://www.functx.com";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

declare namespace json = "http://www.json.org";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace util="http://exist-db.org/xquery/util";

(:lat long:)
declare function local:make-place($nodes as node()*){
  <place xmlns="http://www.tei-c.org/ns/1.0">
    {for $a in $nodes/@* 
     return attribute {node-name($a)} {string($a)}
    }
    <idno>{$nodes//tei:idno[@type='URI'][starts-with(.,$config:base-uri)]}</idno>
    {$nodes/tei:placeName}
    {$nodes/tei:desc[1]}
    {$nodes/tei:location}
  </place>
};

declare function local:make-record(){
    <TEI xmlns="http://www.tei-c.org/ns/1.0">
        <text>
            <body>
            <listPlace>{
                for $n in collection($config:data-root)/descendant::tei:place[descendant::tei:geo]
                return local:make-place($n)
                }</listPlace></body>
        </text>
    </TEI>
};

(: 
 Actions needed by script
 1. Create: create new geojson record from TGN SPARQL endpoint
 2. Update: update geojson record as new records are added/edited (use webhooks)
 3. Link: add links to TEI that reference the places
:)
if(request:get-parameter('action', '') = 'create') then
    try { 
            let $f := local:make-record()
            return xmldb:store(concat($config:app-root,'/resources/lodHelpers'), xmldb:encode-uri('placeNames.xml'), $f)
    } catch *{
        <response status="fail">
            <message>{concat($err:code, ": ", $err:description)}</message>
        </response>
    } 
    
else if(request:get-parameter('action', '') = 'update') then
    try {
        'what do we do here?'
    } catch *{
        <response status="fail">
            <message>{concat($err:code, ": ", $err:description)}</message>
        </response>
    } 
else <div>In progress</div>

