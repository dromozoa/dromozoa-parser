/*jslint this,white*/
"use strict";
(function (root) {
  var console = root.console;
  var parseFloat = root.parseFloat;
  var $ = root.jQuery;
  var d3 = root.d3;
  var setting = root.dromozoa.parser.setting;
  var speed = 400;

  $.noop(console);

  $(function () {
    var svg = d3.select(".tree .body svg");
    var zoom = d3.zoom();
    var zoom_scale;

    $(".menu .head").on("click", function () {
      $(".menu .body").toggle(speed);
    });

    $(".menu .body .toggle").on("click", function () {
      $($(this).data("toggle")).toggle(speed);
    });

    $(".tree").draggable({
      handle: $(".tree .head")
    }).resizable({
      resize: function () {
        var $this = $(this);
        var w = $this.width();
        var h = $this.height() - $(".tree .head").height();
        svg
          .attr("width", w).attr("height", h);
        svg.select(".viewport > rect")
          .attr("width", w).attr("height", h);
      }
    });

    $(".code").draggable({
      handle: $(".code .head")
    });

    svg.select(".viewport")
      .call(zoom.on("zoom", function () {
        var transform = d3.event.transform;
        zoom_scale = transform.k;
        svg.select(".view").attr("transform", transform);
      }))
      .call(zoom.transform, d3.zoomIdentity.translate(setting.node_width * 0.5, svg.attr("height") * 0.5));

    $(".S").on("click", function () {
      var $S = $(this);
      var $T = $("#T" + $S.attr("id").substr(1));
      var t = $T.attr("transform").match(/^translate\((.*?),(.*?)\)$/);
      var zx = svg.attr("width") * 0.5 - parseFloat(t[1]) * zoom_scale;
      var zy = svg.attr("height") * 0.5 - parseFloat(t[2]) * zoom_scale;

      $(".active").removeClass("active");
      $T.addClass("active");
      $S.addClass("active");
      svg.select(".viewport")
        .transition().duration(speed)
        .call(zoom.transform, d3.zoomIdentity.translate(zx, zy).scale(zoom_scale));
    });

    $(".T").on("click", function () {
      var $T = $(this);
      var id = $T.attr("id").substr(1);
      var $S = $(".S" + id);
      var $C = $("#C" + id);

      $(".active").removeClass("active");
      $S.addClass("active");
      $T.addClass("active");
      $C.addClass("active");
      $("html, body").animate({ scrollTop: $S.offset().top }, speed);
    });
  });
}(this.self));
