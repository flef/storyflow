class Controller
  flow: null

  constructor: ->
    d3.json 'data.json', (data) =>
      blame_data = data.blame_data
      history_data = data.history_data

      @flow = new HistoryFlow(blame_data, history_data.numberOfCommit)

$ ->
  window.controller = new Controller