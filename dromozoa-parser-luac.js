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
    var zoom_scale;

    svg.select(".viewport")
      .call(zoom.on("zoom", function () {
        var transform = d3.event.transform;
        zoom_scale = transform.k;
        svg.select(".view").attr("transform", transform);
      }))
      .call(zoom.transform, d3.zoomIdentity.translate(setting.node_width * 0.5, setting.tree_height * 0.5));

//    $(".tree").draggable({
//      handle: $(".tree .head")
//    });
//
//    $(".tree").resizable();

    $(".S").on("click", function () {
      var $T = $(this);
      var $S = $("#T" + $T.attr("id").substr(1));
      var t = $S.attr("transform").match(/^translate\((.*?),(.*?)\)$/);
      var zx = setting.tree_width * 0.5 - parseFloat(t[1]) * zoom_scale;
      var zy = setting.tree_height * 0.5 - parseFloat(t[2]) * zoom_scale;

      $(".active").removeClass("active");
      $S.addClass("active");
      $T.addClass("active");
      svg.select(".viewport")
        .transition().duration(400)
        .call(zoom.transform, d3.zoomIdentity.translate(zx, zy).scale(zoom_scale));
    });

    $(".T").on("click", function () {
      var $T = $(this);
      var $S = $(".S" + $T.attr("id").substr(1));

      $(".active").removeClass("active");
      $S.addClass("active");
      $T.addClass("active");
      $("body").animate({ scrollTop: $S.offset().top });
    });
  });
}(this.self));
