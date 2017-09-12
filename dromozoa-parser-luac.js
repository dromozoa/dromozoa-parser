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

    var move_s = function ($S) {
      $("html, body").animate({ scrollTop: $S.offset().top }, speed);
    };

    var move_t = function ($T) {
      var t = $T.parent().attr("transform").match(/^translate\((.*?),(.*?)\)$/);
      var zx = svg.attr("width") * 0.5 - parseFloat(t[1]) * zoom_scale;
      var zy = svg.attr("height") * 0.5 - parseFloat(t[2]) * zoom_scale;
      svg.select(".viewport")
        .transition().duration(speed)
        .call(zoom.transform, d3.zoomIdentity.translate(zx, zy).scale(zoom_scale));
    };

    $(".menu .head").on("click", function () {
      $(".menu .body").toggle(speed);
    });

    $(".menu .body .toggle").on("click", function () {
      $($(this).data("toggle")).toggle(speed);
    });

    $(".panel").each(function () {
      var $this = $(this);
      $this.draggable({
        scroll: false,
        handle: $this.find(".head")
      });
    });

    $(".tree").resizable({
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
      $(".active").removeClass("active");
      $T.addClass("active");
      $S.addClass("active");
      move_t($T);
    });

    $(".T").on("click", function () {
      var $T = $(this);
      var id = $T.attr("id").substr(1);
      var $S = $(".S" + id);
      $(".active").removeClass("active");
      $S.addClass("active");
      $T.addClass("active");
      move_s($S);
    });

    $("[data-ref]").on("click", function () {
      var id = $(this).data("ref");
      var $S = $(".S" + id);
      var $T = $("#T" + id);

      $(".active").removeClass("active");
      $S.addClass("active");
      $T.addClass("active");
      move_s($S);
      move_t($T);
    });
  });
}(this.self));
