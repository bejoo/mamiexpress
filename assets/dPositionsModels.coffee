positionsApp.module 'Models', (Models, App, Backbone, Marionette, $, _) ->

	class Models.Position extends Backbone.Model
		url: "http://mamiexpress-sapi.bejoo.com/position"
		parse: (pos) ->
			pos.from = new Date pos.from
			pos.to = new Date pos.to
			pos

