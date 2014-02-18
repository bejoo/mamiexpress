positionsApp.module 'Controller', (PositionsController, App, Backbone, Marionette, $, _) ->

	class PositionsController.Controller extends Marionette.Controller
		constructor: ->

		start: ->
			createView = new positionsApp.View.CreatePosition()
			createView.show()
			App.vent.on 'position:add', (position) ->
				that.positions.add position



	PositionsController.addInitializer ->
		controller = new PositionsController.Controller

		controller.start()

