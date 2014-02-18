positionsApp.module 'Controller', (PositionsController, App, Backbone, Marionette, $, _) ->

	class PositionsController.Controller extends Marionette.Controller
		constructor: ->

		start: ->
			console.log positionsApp
			createView = new positionsApp.Views.CreatePosition()
			createView.show()
			App.vent.on 'position:add', (position) ->
				alert "halleluja"



	PositionsController.addInitializer ->
		controller = new PositionsController.Controller

		controller.start()

