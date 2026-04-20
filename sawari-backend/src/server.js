/**
 * Sawari Backend - Main Server File
 * Entry point for the Express application.
 */

// Load environment variables
require('dotenv').config();

// Dependencies
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const path = require('path');

const { errorHandler, notFoundHandler } = require('./middleware/errorHandler');
const db = require('./config/database');

// Route modules
const testRoutes = require('./routes/test.routes');
const authRoutes = require('./routes/auth.routes');
const passengerRoutes = require('./routes/passenger.routes');
const operatorRoutes = require('./routes/operator.routes');
const adminRoutes = require('./routes/admin.routes');
const routesRoutes = require('./routes/routes.routes');
const ridesRoutes = require('./routes/rides.routes');
const transactionsRoutes = require('./routes/transactions.routes');
const complaintsRoutes = require('./routes/complaints.routes');
const notificationsRoutes = require('./routes/notifications.routes');
const paymentRoutes = require('./routes/payment.routes');
const vehicleRoutes = require('./routes/vehicle.routes');

// Initialize Express application
const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());

app.use(cors({
  origin: [
    process.env.FLUTTER_APP_URL,
    process.env.ADMIN_PORTAL_URL,
    'http://localhost:3000',
    'http://localhost:5500',
    'http://localhost:5501',
    'http://127.0.0.1:5500',
    'http://127.0.0.1:5501'
  ],
  credentials: true
}));

// Request logging (development only)
if (process.env.NODE_ENV === 'development') {
  app.use(morgan('dev'));
}

// Body parsing
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use('/uploads', express.static(path.join(__dirname, '..', 'uploads')));

app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Register API routes
app.use('/api/test', testRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/passengers', passengerRoutes);
app.use('/api/operators', operatorRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/routes', routesRoutes);
app.use('/api/rides', ridesRoutes);
app.use('/api/transactions', transactionsRoutes);
app.use('/api/complaints', complaintsRoutes);
app.use('/api/notifications', notificationsRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/vehicles', vehicleRoutes);

app.use(notFoundHandler);
app.use(errorHandler);

const startServer = async () => {
  try {
    await db.query('SELECT NOW()');
    console.log('Database connected successfully');

    app.listen(PORT, () => {
      console.log(`Sawari Backend running on port ${PORT}`);
      console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
    });
  } catch (error) {
    console.error('Failed to start server:', error.message);
    process.exit(1);
  }
};

startServer();

module.exports = app;
