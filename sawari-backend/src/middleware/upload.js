const multer = require('multer');
const path = require('path');
const fs = require('fs');

const fileFilter = (req, file, cb) => {
  const allowedMimes = ['image/jpeg', 'image/png', 'image/jpg', 'application/pdf'];
  const allowedExts = ['.jpg', '.jpeg', '.png', '.pdf'];
  const ext = path.extname(file.originalname).toLowerCase();

  if (allowedMimes.includes(file.mimetype) || allowedExts.includes(ext)) {
    cb(null, true);
  } else {
    const err = new Error('Only JPG, PNG and PDF files are allowed');
    err.statusCode = 400;
    cb(err, false);
  }
};

function createUpload(subfolder) {
  const dir = path.join(__dirname, '..', '..', 'uploads', subfolder);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }

  return multer({
    storage: multer.diskStorage({
      destination: (req, file, cb) => cb(null, dir),
      filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        const ext = path.extname(file.originalname);
        cb(null, `${subfolder}-${uniqueSuffix}${ext}`);
      }
    }),
    fileFilter,
    limits: { fileSize: 5 * 1024 * 1024 }
  });
}

module.exports = {
  vehicleUpload: createUpload('vehicles'),
  operatorUpload: createUpload('operators'),
};
