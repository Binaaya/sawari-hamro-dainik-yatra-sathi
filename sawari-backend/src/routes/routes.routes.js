const express = require('express');
const router = express.Router();
const routesController = require('../controllers/routes.controller');
const { optionalAuth } = require('../middleware/auth');

// Public routes for browsing bus routes

// GET /api/routes - Get all active routes
router.get('/', optionalAuth, routesController.getAllRoutes);

// GET /api/routes/:id - Get route details with stops
router.get('/:id', optionalAuth, routesController.getRouteById);

// GET /api/routes/:id/stops - Get stops for a route
router.get('/:id/stops', optionalAuth, routesController.getRouteStops);

// GET /api/routes/:id/fare - Calculate fare between two stops
router.get('/:id/fare', optionalAuth, routesController.calculateFare);

// GET /api/stops - Get all stops
router.get('/stops/all', optionalAuth, routesController.getAllStops);

// GET /api/routes/search - Search routes by stop names
router.get('/search/by-stops', optionalAuth, routesController.searchRoutesByStops);

module.exports = router;
