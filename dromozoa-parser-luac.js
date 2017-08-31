/*jslint this,white*/
"use strict";
(function (root) {
  var console = root.console;
  var $ = root.jQuery;
  var d3 = root.d3;
  var setting = root.dromozoa.parser.setting;

  $(function () {
    var svg = d3.select(".tree > svg");

    var zoom = d3.zoom();
    var zoom_x;
    var zoom_y;
    var zoom_k;

    svg.select(".viewport")
      .call(zoom.on("zoom", function () {
        var transform = d3.event.transform;
        zoom_x = transform.x;
        zoom_y = transform.y;
        zoom_k = transform.k;
        svg.select(".view").attr("transform", transform);
      }))
      .call(zoom.transform, d3.zoomIdentity.translate(setting.node_width * 0.5, setting.tree_height * 0.5));
  });
}(this.self));
