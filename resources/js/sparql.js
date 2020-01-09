$(document).ready(function () {
    $('#showOtherResources').children('form').each(function () {
        var url = $(this).attr('action');
        $.post(url, $(this).serialize(), function (data) {
            var showOtherResources = $("#listOtherResources");
            var dataArray = data.results.bindings;
            if (! jQuery.isArray(dataArray)) dataArray = [dataArray];
            //Output results if not null
            if (data.results.bindings != null){
                $("#linkedDataBox").removeClass("hidden");
                $.each(dataArray, function (currentIndex, currentElem) {
                    var relatedResources = 'Resources related to <a href="' + currentElem.uri.value + '">' + currentElem.label.value + '</a> '
                    var relatedSubjects = (currentElem.subjects) ? '<div class="indent">' + currentElem.subjects.value + ' related subjects</div>': ''
                    var relatedCitations = (currentElem.citations) ? '<div class="indent">' + currentElem.citations.value + ' related citations</div>': ''
                    showOtherResources.append(
                    '<div>' + relatedResources + relatedCitations + relatedSubjects + '</div>');
                });
            }
        }).fail(function (jqXHR, textStatus, errorThrown) {
            console.log('Error code here: ' + textStatus);
        });
    });
    $('#getMoreLinkedData').one("click", function (e) {
        $('#showMoreResources').children('form').each(function () {
            var url = $(this).attr('action');
            $.post(url, $(this).serialize(), function (data) {
                var showOtherResources = $("#showMoreResources");
                var dataArray = data.results.bindings;
                if (! jQuery.isArray(dataArray)) dataArray =[dataArray];
                //Output results if not null
                if (data.results.bindings != null){
                    $.each(dataArray, function (currentIndex, currentElem) {
                        var relatedResources = 'Resources related to <a href="' + currentElem.uri.value + '">' + currentElem.label.value + '</a> '
                        var relatedSubjects = (currentElem.subjects) ? '<div class="indent">' + currentElem.subjects.value + ' related subjects</div>': ''
                        var relatedCitations = (currentElem.citations) ? '<div class="indent">' + currentElem.citations.value + ' related citations</div>': ''
                        showOtherResources.append(
                        '<div>' + relatedResources + relatedCitations + relatedSubjects + '</div>');
                    });
                 }   
            }).fail(function (jqXHR, textStatus, errorThrown) {
                console.log(textStatus);
            });
        });
    });
});