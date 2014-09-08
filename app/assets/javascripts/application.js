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
var SyncOperationsController = Paloma.controller('SyncOperations');

DefinitionsController.prototype.show = function() {
  $("select").change(function() {
    if (this.value == "") return;

    var self = this,
      hidden_d_field_element = $('input#d_field_' + self.value),
      d_field = JSON.parse(hidden_d_field_element.val()),
      header_name = $(this).parent().prev().text().trim(),
      tag_prefix = "td[id='mapping[" + header_name + "]";

   $(tag_prefix + "[description]']").text(d_field.description);
   $(tag_prefix + "[data_type]']").text(d_field.data_type);
   $(tag_prefix + "[is_required]']").text(d_field.is_required);
   $(tag_prefix + "[allows_null]']").text(d_field.allows_null);
  }).change();
};

SyncOperationsController.prototype.show = function() {
  $(document).on('ready, page:change', function() {
    var editableGrid = new EditableGrid("RequestInput"),
        params = Paloma.engine._request.params,
        grid_path = params['source_data_grid_link'] + '.json';

    editableGrid.tableLoaded = function() {
      this.renderGrid("tablecontent", "table-editor");
    };

    editableGrid.loadJSON(grid_path);
  });
};


