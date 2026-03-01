const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const connectDB = require('./src/config/database');

dotenv.config();
connectDB();

const app = express();

app.use(cors({
  origin: ['http://localhost:8080', 'http://10.0.2.2:8080', 'http://127.0.0.1:8080'],
  credentials: true
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use('/api/auth', require('./src/routes/authRoutes'));

app.get('/', (req, res) => {
  res.json({ message: 'API My School opérationnelle' });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`🚀 Serveur démarré sur le port ${PORT}`);
});