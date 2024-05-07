$(document).ready(function(){
 
    var topic = $('h2');
    if (topic.length > 0) {
        $('<div class="sidebar"><span class="sidebarheading">On this page</span><div class="sidebartoc"><ul class="innerstep"></ul></div></div>').insertBefore('#page-toc');
 
        $(topic).each(function () {
            var topicName = $(this).text(); //get the name that will be displayed in the nav box
            var linkName = topicName.replace(/\s/g, ''); //edit the name for use as an anchor
            $('<a name="' + linkName + '"></a>').prependTo(this); //puts an anchor with a name attribute we created by the topic so we can link to it
            $('<li><a class="topiclink navlinks" href="#' + linkName + '">' + topicName + '</a></li>').appendTo('ul.innerstep'); //nests the subheading under its heading in the navigation box
        })
 
			
    }
});