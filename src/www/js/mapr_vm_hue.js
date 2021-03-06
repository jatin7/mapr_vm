//
// Pre-load script files that are necessary for the app to function.
//
//


/*jshint bitwise:true, curly:true, eqeqeq:true, forin:true, immed:true, indent:4, latedef:true, newcap:true,
noarg:true, noempty:true, nonew:true, plusplus:true, quotmark:double, regexp:true, undef:true, unused:true,
strict: true, trailing:true, maxdepth: 4, maxstatements:40, maxlen:120, browser:true, jquery:true*/
/*global require:true*/


// Initialize require
// Call init which should load all items that should be loaded on runtime.
require(["./config"], function () {
    "use strict";
    require(["jquery", "underscore", "jqueryui", "utility/JQueryPlugins",
            "tmpl/TemplateHelpers", "views/tutorial/Init"],
            function ($, _, $ui, $plugin, tmplHelper, Tutorial) {

        $(function () { // Document Ready
            Tutorial.start();
        });

    });
});


