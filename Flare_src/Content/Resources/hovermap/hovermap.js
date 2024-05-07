/* <![CDATA[ */
$(document).ready(function () {
	'use strict';

	$('.hoverMap').hover(function () {
		$(this.id).add('.mapLink').addClass('disableStuff');
	});

	$('.mapLink').hover(function () {
		var bw = parseInt($(this).css('borderLeftWidth'), 10);
		var position = $(this).position();
		$(this).css({
			'background-image': 'url(' + $('.mapImage').attr('src') + ')',
			'background-position': 'top -' + (position.top + bw) + 'px' + ' ' + 'left -' + (position.left + bw) + 'px',
			'background-repeat': 'no-repeat'
		});
	},
	function () {
		$(this).css({
			'background-image': 'none'
		});
	});

	$('.mapLink').each(function () {
		var data = $(this).data();
		var title = $(this).attr('href');
		var target = 'false';
		var offsetX = 0;
		var offsetY = 0;
		var my = 'bottom left';
		var at = 'top right';

		if ($(this).attr('data-tooltip-atParent') === "true") {
			target = $(this).parent();
		}

		$(this).qtip({
			prerender: true,
			style: {
				tip: {
					corner: false
				},
				classes: 'qtip-bootstrap popUp'
			},
			show: {
				solo: true
			},
			position: {
				viewport: $(window),
				my: my,
				at: at,
				target: target,
				adjust: {
					method: 'shift',
					x: offsetX,
					y: offsetY
				}
			},
			content: {
				text: $('div' + title).html()
			},
			hide: {
				fixed: true,
				delay: 300
			}
		});

		for (var i in data) {
			$(this).qtip('api').set(i, data[i]);
		}
	});

	$('.mapLink').click(function (event) {
		event.preventDefault();
	});
});
/* ]]> */