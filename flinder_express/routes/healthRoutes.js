const express = require('express');
const router = express.Router();
const { check } = require('../controllers/healthController');

// Health check endpoint
router.get('/', check);

module.exports = router; 