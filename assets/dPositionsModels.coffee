positionsApp.module 'Models', (Models, App, Backbone, Marionette, $, _) ->

	class Models.Position extends Backbone.Model
		parse: (pos) ->
			pos.from = new Date pos.from
			pos.to = new Date pos.to
			pos

	class Models.Positions extends Backbone.Collection
		model: Models.Position
		url: "#{Bejoo.sapiURL}position"

		comparator: (a, b) ->
			if a.get('from') > b.get('from')
				1
			else
				-1
