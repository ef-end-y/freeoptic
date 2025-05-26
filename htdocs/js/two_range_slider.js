(function($)
{
	$.fn.two_range_slider = function(options)
	{
		let settings = $.extend({
			step: 1,
			value_padding: 1,
			show_value: undefined
		}, options );

		const step = settings.step;

		const min_value = settings.min - settings.value_padding;
		const max_value = settings.max + settings.value_padding;

		const show_min_value = settings.show_value ? settings.show_value(min_value) : min_value;
		const show_max_value = settings.show_value ? settings.show_value(max_value) : max_value;

		let outer_slider  = $('<div></div>', { class: 'two-range-slider-outer' });
		let inner_slider  = $('<div></div>', { class: 'two-range-slider-inner' });
		let min_value_indicator  = $('<div></div>', { class: 'two-range-slider-min-value', html: show_min_value });
		let max_value_indicator  = $('<div></div>', { class: 'two-range-slider-max-value', html: show_max_value });

		outer_slider.append(min_value_indicator, max_value_indicator);
		this.append(outer_slider, inner_slider);

		inner_slider.slider({
			range: true,
			min: settings.min - settings.value_padding,
			max: settings.max + settings.value_padding,
			step: step,
			slide: function( event, ui ) {
				const ai = ui.values[0];
				const bi = ui.values[1];
				if( ai < (settings.min+step) || bi > (settings.max-step) || Math.abs(bi-ai) < step ) {
					return false;
				}
				const ao = outer_slider.slider('values', 0);
				const bo = outer_slider.slider('values', 1);
				if( ai < (ao+step) || bi > (bo-step) ) {
					return false;
				}
				show_values_on_sliders([ao, ai, bi, bo]);
				return true;
			}
		});

		outer_slider.slider({
			range: true,
			min: settings.min - settings.value_padding,
			max: settings.max + settings.value_padding,
			step: step,
			slide: function( event, ui ) {
				const ao = ui.values[0];
				const bo = ui.values[1];
				const ai = inner_slider.slider('values', 0);
				const bi = inner_slider.slider('values', 1);
				if( ao < settings.min ) {
					outer_slider.slider('values', 0, settings.min);
					show_values_on_sliders([settings.min, ai, bi, bo]);
					return false;
				}
				if( bo > settings.max ) {
					outer_slider.slider('values', 1, settings.max);
					show_values_on_sliders([ao, ai, bi, settings.max]);
					return false;
				}
				if( ao > (ai-step) || bo < (bi+step) || Math.abs(bo-ao) < step  ) {
					return false;
				}
				show_values_on_sliders([ao, ai, bi, bo]);
				return true;
			}
		});

		let sliders = [ [outer_slider, 0], [inner_slider, 0], [inner_slider, 1], [outer_slider, 1] ];

		function show_values_on_sliders(sliders_values) {
			if( settings.callback ) {
				settings.callback(sliders_values);
			}
			for( const slider of sliders ) {
				const value = sliders_values.shift();
				const show_value = settings.show_value ? settings.show_value(value) : value;
				$(slider[0].find('.ui-slider-handle').get(slider[1])).html(show_value);
				values.push(value);
			}
		}

		let values = options.values;
		if( !(
			values &&
			values.length === 4 &&
			+values[0] >= settings.min &&
			+values[1] >= (+values[0] + step) &&
			+values[2] >= (+values[1] + step) &&
			+values[3] >= (+values[2] + step) &&
			+values[1] <= settings.max
		)) {
			const range = Math.abs(settings.max - settings.min);
			const segment = Math.floor(range / 3 / step) * step;
			values = [
				settings.min,
				settings.min + segment,
				settings.min + segment + segment,
				settings.max
			];
		}
		show_values_on_sliders(values);
		for( const slider of sliders ) {
			slider[0].slider('values', slider[1], +values.shift());
		}

		return this;
	};
})(jQuery);
