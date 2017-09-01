/*jslint this,white*/
"use strict";
(function (root) {
  var console = root.console;
  var parseFloat = root.parseFloat;
  var $ = root.jQuery;
  var d3 = root.d3;
  var setting = root.dromozoa.parser.setting;

  $.noop(console);

  $(function () {
    var svg = d3.select(".tree svg");
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

    $(".S").on("click", function () {
      var $T = $(this);
      var id = $T.attr("id").substr(1);
      var $S = $("#T" + id);
      var t = $S.attr("transform").match(/^translate\((.*?),(.*?)\)$/);
      var zx = setting.tree_width * 0.5 - parseFloat(t[1]) * zoom_k;
      var zy = setting.tree_height * 0.5 - parseFloat(t[2]) * zoom_k;

      $(".active").removeClass("active");
      $S.addClass("active");
      $T.addClass("active");
      svg.select(".viewport")
        .transition().duration(400)
        .call(zoom.transform, d3.zoomIdentity.translate(zx, zy).scale(zoom_k));
    });

    $(".T").on("click", function () {
      var $T = $(this);
      var id = $T.attr("id").substr(1);
      var $S = $(".S" + id);

      $(".active").removeClass("active");
      $S.addClass("active");
      $T.addClass("active");
      $("body").animate({ scrollTop: $S.offset().top });
    });
  });
}(this.self));
