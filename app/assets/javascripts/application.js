// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require turbolinks
//= require paloma
//= require_tree .

var DefinitionsController = Paloma.controller('Definitions');

DefinitionsController.prototype.show = function() {
  $("select").change(function() {
    var $element = $('#d_field_' + this.value),
      d_field = JSON.parse($element.attr('value')),
      header_name = $(this).parent().prev().text(),
      tag_prefix = "td[id='mapping[" + header_name + "]";

   if (this.value == "") return;

   $(tag_prefix + "[description]']").text(d_field.description);
   $(tag_prefix + "[data_type]']").text(d_field.data_type);
   $(tag_prefix + "[is_required]']").text(d_field.is_required);
   $(tag_prefix + "[allows_null]']").text(d_field.allows_null);
  }).change();
};
