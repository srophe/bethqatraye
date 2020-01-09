xquery version "3.1";

import module namespace http="http://expath.org/ns/http-client";
(:~
 : Take posted SPARQL query and send it to the Syriaca.org SPARQL endpoint
 : Returns JSON
:)


let $query := 
            if(request:get-parameter('query', '')) then  request:get-parameter('query', '') 
            else request:get-data() 
let $results :=
    try{
        if($query != '') then 
            util:base64-decode(http:send-request(<http:request href="http://wwwb.library.vanderbilt.edu/exist/apps/srophe/api/sparql?format=json&amp;query={fn:encode-for-uri($query)}" method="get"/>)[2])
        else 'No query data'
    } catch * {
        concat('Caught error', $err:code,': ',$err:description)
    } 
return (response:set-header("Content-Type", "application/json"), $results)
    