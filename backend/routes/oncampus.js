// backend/routes/oncampus.js
const express = require('express');
const router = express.Router();
const path = require('path');
const fs = require('fs');
const multer = require('multer');
const PDFDocument = require('pdfkit');

const OnCampusDrive = require('../models/onCampusDrive');

// Multer setup: store resumes in uploads/resumes
const uploadDir = path.join(__dirname, '..', 'uploads', 'resumes');
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadDir),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    cb(null, Date.now().toString() + '-' + Math.round(Math.random()*1e6) + ext);
  },
});
const upload = multer({ storage });

// GET all drives
router.get('/', async (req, res) => {
  try {
    const drives = await OnCampusDrive.find().sort({ dateOfRecruitment: -1 });
    res.json(drives);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// GET single drive
router.get('/:id', async (req, res) => {
  try {
    const d = await OnCampusDrive.findById(req.params.id);
    if (!d) return res.status(404).json({ message: 'Not found' });
    res.json(d);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// CREATE drive
router.post('/', async (req, res) => {
  try {
    const payload = req.body;
    // if date string provided, convert
    if (payload.dateOfRecruitment) payload.dateOfRecruitment = new Date(payload.dateOfRecruitment);
    const drive = new OnCampusDrive(payload);
    await drive.save();
    res.status(201).json(drive);
  } catch (err) { res.status(400).json({ error: err.message }); }
});

// UPDATE drive
router.put('/:id', async (req, res) => {
  try {
    const payload = req.body;
    if (payload.dateOfRecruitment) payload.dateOfRecruitment = new Date(payload.dateOfRecruitment);
    const drive = await OnCampusDrive.findByIdAndUpdate(req.params.id, payload, { new: true });
    res.json(drive);
  } catch (err) { res.status(400).json({ error: err.message }); }
});

// DELETE drive
router.delete('/:id', async (req, res) => {
  try {
    const drive = await OnCampusDrive.findByIdAndDelete(req.params.id);
    res.json({ message: 'Deleted', driveId: drive ? drive._id : null });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// --- Students routes (embedded) ---

// Add student with optional resume upload (field name 'resume')
router.post('/:id/students', upload.single('resume'), async (req, res) => {
  try {
    const drive = await OnCampusDrive.findById(req.params.id);
    if (!drive) return res.status(404).json({ message: 'Drive not found' });

    const student = {
      name: req.body.name || '',
      mobile: req.body.mobile || '',
      email: req.body.email || '',
      resumePath: req.file ? path.join('uploads', 'resumes', req.file.filename) : ''
    };
    drive.students.push(student);
    drive.totalStudents = drive.totalStudents + 1;
    await drive.save();
    res.status(201).json(drive);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// Update student (optional resume)
router.put('/:id/students/:studentId', upload.single('resume'), async (req, res) => {
  try {
    const drive = await OnCampusDrive.findById(req.params.id);
    if (!drive) return res.status(404).json({ message: 'Drive not found' });

    const s = drive.students.id(req.params.studentId);
    if (!s) return res.status(404).json({ message: 'Student not found' });

    s.name = req.body.name ?? s.name;
    s.mobile = req.body.mobile ?? s.mobile;
    s.email = req.body.email ?? s.email;

    if (req.file) {
      // delete previous file if exists
      if (s.resumePath) {
        const prev = path.join(__dirname, '..', s.resumePath);
        if (fs.existsSync(prev)) fs.unlinkSync(prev);
      }
      s.resumePath = path.join('uploads', 'resumes', req.file.filename);
    }

    await drive.save();
    res.json(drive);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// Delete student
router.delete('/:id/students/:studentId', async (req, res) => {
  try {
    const drive = await OnCampusDrive.findById(req.params.id);
    if (!drive) return res.status(404).json({ message: 'Drive not found' });

    const s = drive.students.id(req.params.studentId);
    if (!s) return res.status(404).json({ message: 'Student not found' });

    // delete resume file if exists
    if (s.resumePath) {
      const fp = path.join(__dirname, '..', s.resumePath);
      if (fs.existsSync(fp)) fs.unlinkSync(fp);
    }

    s.remove();
    drive.totalStudents = Math.max(0, drive.totalStudents - 1);
    await drive.save();
    res.json({ message: 'Student deleted', drive });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// Download resume file  MUST COME FIRST
router.get('/resume/:filename', (req, res) => {
  const file = path.join(__dirname, '..', 'uploads', 'resumes', req.params.filename);
  if (fs.existsSync(file)) {
    res.download(file);
  } else res.status(404).json({ message: 'File not found' });
});

// Export drive as PDF
router.get('/:id/export', async (req, res) => {
  try {
    const drive = await OnCampusDrive.findById(req.params.id);
    if (!drive) return res.status(404).json({ message: 'Drive not found' });

    const doc = new PDFDocument({ margin: 30 });
    res.setHeader('Content-disposition', `attachment; filename=drive-${drive._id}.pdf`);
    res.setHeader('Content-type', 'application/pdf');
    doc.pipe(res);

    doc.fontSize(18).text(`On-Campus Drive: ${drive.collegeName}`, { underline: true });
    doc.moveDown();
    doc.fontSize(12).text(`Date: ${drive.dateOfRecruitment.toISOString().slice(0,10)}`);
    doc.text(`Selected Position: ${drive.selectedPosition}`);
    doc.text(`BG Verification: ${drive.bgVerificationStatus}`);
    doc.text(`Contact Person: ${drive.contactPerson}`);
    doc.moveDown();

    doc.fontSize(14).text('Summary', { underline: true });
    doc.fontSize(12).list([
      `Total Students: ${drive.totalStudents}`,
      `Aptitude Selected: ${drive.aptitudeSelected}`,
      `Tech Selected: ${drive.techSelected}`,
      `HR Selected: ${drive.hrSelected}`
    ]);
    doc.moveDown();

    doc.fontSize(14).text('Students', { underline: true });
    drive.students.forEach((s, idx) => {
      doc.fontSize(12).text(`${idx+1}. ${s.name} — ${s.mobile} — ${s.email}`);
    });

    doc.end();
  } catch (err) { res.status(500).json({ error: err.message }); }
});

module.exports = router;
