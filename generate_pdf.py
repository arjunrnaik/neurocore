import os
from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Image, Table, TableStyle
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch

def create_pdf():
    pdf_path = os.path.abspath("NeuroCore_UI_Showcase.pdf")
    doc = SimpleDocTemplate(
        pdf_path,
        pagesize=letter,
        rightMargin=40, leftMargin=40, topMargin=40, bottomMargin=40
    )

    styles = getSampleStyleSheet()
    title_style = ParagraphStyle(
        'TitleStyle',
        parent=styles['Heading1'],
        fontSize=24,
        textColor=colors.HexColor("#0F172A"),
        spaceAfter=8,
        alignment=1 # Centered
    )
    subtitle_style = ParagraphStyle(
        'SubTitleStyle',
        parent=styles['Normal'],
        fontSize=13,
        textColor=colors.HexColor("#3B82F6"),
        spaceAfter=20,
        alignment=1,
        fontName="Helvetica-Bold"
    )
    body_style = ParagraphStyle(
        'BodyStyle',
        parent=styles['Normal'],
        fontSize=11,
        textColor=colors.HexColor("#1E293B"),
        spaceAfter=12,
        leading=16
    )
    bullet_style = ParagraphStyle(
        'BulletStyle',
        parent=styles['Normal'],
        fontSize=11,
        textColor=colors.HexColor("#334155"),
        leftIndent=20,
        spaceAfter=8,
        leading=15
    )

    story = []

    # Title & Subtitle
    story.append(Paragraph("NeuroCore Android App Showcase", title_style))
    story.append(Paragraph("Local-First AI Personal Operating System • Built with Flutter Dart", subtitle_style))
    story.append(Spacer(1, 10))

    # Image embedding
    img_path = r"C:\Users\DELL\.gemini\antigravity\brain\0c11face-b859-4543-8f62-1ea34c39bc5f\neurocore_app_ui_mockup_1782735295394.png"
    if os.path.exists(img_path):
        # Resize image proportionally to fit width
        img = Image(img_path, width=5.5 * inch, height=5.5 * inch)
        img.hAlign = 'CENTER'
        story.append(img)
        story.append(Spacer(1, 20))

    # Architecture Overview Table
    story.append(Paragraph("<b>Core App Features & Architecture</b>", ParagraphStyle('SubHead', parent=styles['Heading2'], fontSize=16, textColor=colors.HexColor("#0F172A"), spaceAfter=10)))
    
    data = [
        ["Component", "Technology / Specification", "Key Benefit"],
        ["Local Database", "SQLite (sqflite package)", "100% of user data stays safely on device."],
        ["AI Intelligence", "Google Gemini 2.5 Flash", "Direct REST connection; each user inputs free key."],
        ["Voice Input", "Android Speech to Text", "Tap-to-speak voice note transcription."],
        ["Cloud Compiler", "GitHub Actions CI/CD", "Automated .apk building in the cloud without PC setup."]
    ]
    t = Table(data, colWidths=[1.5*inch, 2.3*inch, 3.2*inch])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor("#1E293B")),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
        ('BOTTOMPADDING', (0,0), (-1,0), 8),
        ('BACKGROUND', (0,1), (-1,-1), colors.HexColor("#F8FAFC")),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#CBD5E1")),
        ('FONTSIZE', (0,0), (-1,-1), 10),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('PADDING', (0,0), (-1,-1), 8),
    ]))
    story.append(t)
    story.append(Spacer(1, 20))

    # Highlights
    story.append(Paragraph("<b>Design Highlights</b>", ParagraphStyle('SubHead2', parent=styles['Heading2'], fontSize=16, textColor=colors.HexColor("#0F172A"), spaceAfter=10)))
    story.append(Paragraph("• <b>Material 3 Dark Theme:</b> Deep navy background (#0F172A) optimizes AMOLED screen battery life.", bullet_style))
    story.append(Paragraph("• <b>Live Habit Streaks:</b> Glowing neon badges track consecutive daily logging across Finance, Health, and Tasks.", bullet_style))
    story.append(Paragraph("• <b>Seamless Sharing:</b> The generated APK can be forwarded to friends & family so they run their own private instance.", bullet_style))

    doc.build(story)
    print(f"Successfully generated PDF at: {pdf_path}")

if __name__ == "__main__":
    create_pdf()
