window.MainCntl = ($scope, $route, $routeParams, $location, $http) ->
  $scope.$route = $route
  $scope.$location = $location
  $scope.$routeParams = $routeParams

DashCntl = ($scope, $routeParams, $resource) ->
  $scope.$resource = $resource
  $scope.name = "DashCntl"
  $scope.params = $routeParams

AddTitleCntl = ($scope, $routeParams) ->
  $scope.name = "AddTitleCntl"
  $scope.params = $routeParams

mod = ($routeProvider, $locationProvider) ->
  $routeProvider.when "/dash",
    templateUrl: "/dash.html"
    controller: DashCntl

  $routeProvider.when "/addtitle",
    templateUrl: "/addtitle.html"
    controller: AddTitleCntl

  $locationProvider.html5Mode true

viewMod = angular.module "ngView", [ "ngResource" ], mod


viewMod.directive "feed", ($resource) ->
  restrict: "E"
  replace: true
  transclude: false
  template: "<li ng-repeat=\"article in articles\"><a href=\"{{article.link}}\" target=\"_blank\" >{{article.title}}</a></li>"
  link: (scope, element, attrs) ->
    Feed = $resource "/feed/" + encodeURIComponent(attrs.url)
    scope.articles = Feed.query( {  }, ->  )

viewMod.directive "upcoming", ($resource) ->
  restrict: "E"
  replace: true
  transclude: false
  template: "<li ng-repeat=\"ev in evts\">{{ev.date}} {{ev.title}}</li>"
  link: (scope, element, attrs) ->
    Upcoming = $resource "/upcoming"
    scope.evts = Upcoming.query( { blah: 'hello' }, ->  )

viewMod.directive 'tabs', ->
  restrict: 'E'
  transclude: true
  scope: {}
  controller: ($scope, $element) ->
    panes = $scope.panes = []

    $scope.select = (pane) ->
      for p in panes
        p.selected = false
      pane.selected = true

    @addPane = (pane) ->
      if panes.length is 0 then $scope.select pane
      panes.push pane
  template:
    """
    <div class="tabbable">
      <ul class="nav nav-tabs">
        <li ng-repeat="pane in panes" ng-class="{active:pane.selected}">
          <a href="" ng-click="select(pane)">{{pane.title}}</a>
        </li>
      </ul>
      <div class="tab-content" ng-transclude></div>
    </div>
    """
  replace: true

viewMod.directive 'pane', ->
  require: '^tabs'
  restrict: 'E'
  transclude: true
  scope: { title: '@' }
  link: (scope, element, attrs, tabsCtrl) ->
    tabsCtrl.addPane scope
  template:
    '<div class="tab-pane" ng-class="{active: selected}" ng-transclude>' +
    '</div>'
  replace: true
