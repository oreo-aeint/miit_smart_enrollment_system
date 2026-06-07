const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

admin.initializeApp();

// Your Gmail credentials (set via Firebase config)
const emailUser = functions.config().email.user;
const emailPass = functions.config().email.pass;

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: { user: emailUser, pass: emailPass },
});

exports.sendTranscriptEmail = functions.https.onCall(async (data, context) => {
  // Check authentication
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
  }

  const { to, subject, body, attachmentBase64, attachmentName } = data;

  if (!to || !subject || !body || !attachmentBase64 || !attachmentName) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
  }

  // Clean base64 string
  let cleanBase64 = attachmentBase64;
  if (attachmentBase64.includes('base64,')) {
    cleanBase64 = attachmentBase64.split('base64,').pop();
  }

  try {
    const mailOptions = {
      from: `"MIIT Registrar" <${emailUser}>`,
      to: to,  // ✅ Student email auto-filled here!
      subject: subject,
      html: body,
      attachments: [{
        filename: attachmentName,
        content: cleanBase64,
        encoding: 'base64',
        contentType: 'application/pdf',
      }],
    };

    const info = await transporter.sendMail(mailOptions);

    // Log to Firestore
    await admin.firestore().collection('email_logs').add({
      to: to,
      subject: subject,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'sent',
      messageId: info.messageId,
    });

    return { success: true, messageId: info.messageId };
  } catch (error) {
    console.error('Error:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send email');
  }
});