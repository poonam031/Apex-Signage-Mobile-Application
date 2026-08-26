import { PrismaClient, UserRole, SiteVisitStatus, JobStage, JobStatus, MachineType, InventoryCategory, InventoryUnit, StockTransactionType, AttendanceStatus, AttendanceMethod, RewardCategory, QuotationStatus, InvoiceStatus, PaymentMethod } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  console.log('--- Starting Signage System Database Seeding ---');

  // Clean existing tables (in proper order for foreign keys)
  await prisma.auditLog.deleteMany();
  await prisma.notification.deleteMany();
  await prisma.customerFeedback.deleteMany();
  await prisma.pettyCashExpense.deleteMany();
  await prisma.payment.deleteMany();
  await prisma.invoiceItem.deleteMany();
  await prisma.invoice.deleteMany();
  await prisma.quotationItem.deleteMany();
  await prisma.quotation.deleteMany();
  await prisma.leaderboardMonth.deleteMany();
  await prisma.rewardPoint.deleteMany();
  await prisma.salarySlip.deleteMany();
  await prisma.attendance.deleteMany();
  await prisma.stockTransaction.deleteMany();
  await prisma.inventoryItem.deleteMany();
  await prisma.dailyProductionReport.deleteMany();
  await prisma.machine.deleteMany();
  await prisma.designFile.deleteMany();
  await prisma.jobStageHistory.deleteMany();
  await prisma.measurement.deleteMany();
  await prisma.siteMedia.deleteMany();
  await prisma.technicalChecklist.deleteMany();
  await prisma.jobCard.deleteMany();
  await prisma.siteVisit.deleteMany();
  await prisma.customer.deleteMany();
  await prisma.user.deleteMany();
  await prisma.appSetting.deleteMany();

  // 1. App Settings
  console.log('Seeding App Settings...');
  await prisma.appSetting.createMany({
    data: [
      {
        key: 'COMPANY_PROFILE',
        category: 'BUSINESS',
        description: 'Company Details for Invoices and Branding',
        value: JSON.stringify({
          name: 'Apex Signage & Printing Solutions',
          tagline: 'Leading Outdoor & Indoor Branding Specialists',
          address: 'Plot 42, Industrial Area Phase 2, Mumbai, Maharashtra 400093',
          phone: '+91 98765 00000',
          email: 'contact@apexsignage.com',
          website: 'https://apexsignage.com',
          gstNumber: '27AABCS1429B1Z8',
          panNumber: 'AABCS1429B',
          logoUrl: 'https://via.placeholder.com/200x80.png?text=Apex+Signage',
          terms: '1. 50% Advance with Purchase Order.\n2. Goods once delivered cannot be returned.\n3. 1 Year warranty on LED modules only.'
        })
      },
      {
        key: 'GEOFENCE_CONFIG',
        category: 'ATTENDANCE',
        description: 'Factory geofence settings for automated check-in',
        value: JSON.stringify({
          latitude: 19.0760,
          longitude: 72.8777,
          radiusMeters: 200,
          factoryName: 'Apex Signage Main Workshop'
        })
      },
      {
        key: 'REWARD_RULES',
        category: 'GAMIFICATION',
        description: 'Points configuration for employee achievements',
        value: JSON.stringify({
          pointsPer100SqFt: 50,
          zeroWasteBonusPoints: 100,
          timelyInstallPoints: 80,
          fiveStarRatingPoints: 150,
          perfectAttendancePoints: 200,
          employeeOfMonthRewardAmount: 3000
        })
      },
      {
        key: 'MATERIAL_RATES',
        category: 'PRICING',
        description: 'Default sq.ft rates for quotation calculations',
        value: JSON.stringify({
          'Flex 240 GSM': 18,
          'Star Flex 440 GSM': 32,
          'Blackout Flex': 45,
          'Vinyl on Sunboard 3mm': 65,
          'Vinyl on Sunboard 5mm': 85,
          'ACP Cladding Sheet': 220,
          'Acrylic LED 3D Letters': 380,
          'Framing 1x1 MS Structure': 40,
          'Installation Normal': 25,
          'Installation Height/Crane': 60
        })
      }
    ]
  });

  // 2. Users (4 Roles)
  console.log('Seeding Users across 4 Roles...');
  const salt = await bcrypt.genSalt(10);
  const adminPassword = await bcrypt.hash('admin123', salt);
  const fieldBoyPassword = await bcrypt.hash('field123', salt);
  const designerPassword = await bcrypt.hash('design123', salt);
  const installerPassword = await bcrypt.hash('install123', salt);

  const superAdmin = await prisma.user.create({
    data: {
      email: 'admin@signage.com',
      phone: '+919876543210',
      name: 'Rajesh Singhania (Super Admin)',
      passwordHash: adminPassword,
      role: UserRole.SUPER_ADMIN,
      baseSalary: 65000.0
    }
  });

  const fieldBoy = await prisma.user.create({
    data: {
      email: 'fieldboy@signage.com',
      phone: '+919876543211',
      name: 'Rahul Sharma (Field Boy)',
      passwordHash: fieldBoyPassword,
      role: UserRole.FIELD_BOY,
      baseSalary: 18000.0
    }
  });

  const designerOperator = await prisma.user.create({
    data: {
      email: 'designer@signage.com',
      phone: '+919876543212',
      name: 'Amit Verma (Designer & Operator)',
      passwordHash: designerPassword,
      role: UserRole.DESIGNER_OPERATOR,
      baseSalary: 28000.0
    }
  });

  const installer = await prisma.user.create({
    data: {
      email: 'installer@signage.com',
      phone: '+919876543213',
      name: 'Vikram Singh (Installation Lead)',
      passwordHash: installerPassword,
      role: UserRole.INSTALLATION_TEAM,
      baseSalary: 22000.0
    }
  });

  // 3. Customers
  console.log('Seeding Customers...');
  const customer1 = await prisma.customer.create({
    data: {
      name: 'Sunil Mehta',
      companyName: 'Apex Retail Fashion Store',
      phone: '+919820011223',
      email: 'sunil@apexretail.com',
      address: 'Shop 14, Grand Galleria Mall, Link Road, Andheri West, Mumbai',
      gstNumber: '27AABCM8899K1Z4',
      latitude: 19.1363,
      longitude: 72.8277,
      notes: 'Requires premium LED front-lit ACP board with warranty.'
    }
  });

  const customer2 = await prisma.customer.create({
    data: {
      name: 'Dr. Priya Nair',
      companyName: 'CarePlus Multispeciality Hospital',
      phone: '+919830022334',
      email: 'priya@careplushospital.org',
      address: 'Plot 7, Sector 15, Vashi, Navi Mumbai',
      gstNumber: '27AABCU7744P1Z2',
      latitude: 19.0770,
      longitude: 72.9980,
      notes: 'Emergency 24x7 Glow sign and wayfinding directional signage.'
    }
  });

  const customer3 = await prisma.customer.create({
    data: {
      name: 'Karan Kapoor',
      companyName: 'Urban Crust Gourmet Pizza',
      phone: '+919811133445',
      email: 'karan@urbancrust.in',
      address: 'Ground Floor, Hiranandani Estate, Thane West',
      latitude: 19.2482,
      longitude: 72.9818
    }
  });

  // 4. Machines
  console.log('Seeding Production Machines...');
  const ecoSolventMachine = await prisma.machine.create({
    data: {
      name: 'Roland TrueVIS SG2-640',
      type: MachineType.ECO_SOLVENT,
      model: 'SG2-640 (64 Inch)',
      maxCapacitySqFtPerDay: 800.0,
      notes: 'High-definition vinyl and photo paper printing'
    }
  });

  const uvMachine = await prisma.machine.create({
    data: {
      name: 'Apex UV Flatbed 2513',
      type: MachineType.UV,
      model: 'UV-2513 Ricoh Gen6',
      maxCapacitySqFtPerDay: 600.0,
      notes: 'Direct print on Acrylic, Sunboard, Glass & Wood'
    }
  });

  const solventMachine = await prisma.machine.create({
    data: {
      name: 'StarFire 3200 Solvent Heavy Duty',
      type: MachineType.SOLVENT,
      model: 'SF-3200 (10.5 ft)',
      maxCapacitySqFtPerDay: 2500.0,
      notes: 'Outdoor large format flex printing'
    }
  });

  const cncMachine = await prisma.machine.create({
    data: {
      name: 'Omni CNC Router 1325',
      type: MachineType.CNC_ROUTER,
      model: '1325 Auto Tool Changer',
      maxCapacitySqFtPerDay: 400.0,
      notes: '3D Acrylic letters, MDF & ACP cutting'
    }
  });

  // 5. Inventory Items
  console.log('Seeding Inventory Items with Minimum Stock Alert Thresholds...');
  const flexRoll = await prisma.inventoryItem.create({
    data: {
      name: 'Star Flex 440 GSM (10ft x 150ft Roll)',
      category: InventoryCategory.ROLL_FEET,
      unit: InventoryUnit.ROLL,
      currentStock: 14.0,
      minStockAlert: 5.0,
      costPrice: 2800.0,
      sellingPrice: 4200.0,
      supplierName: 'National Flex Distributors'
    }
  });

  const vinylRoll = await prisma.inventoryItem.create({
    data: {
      name: 'Avery Dennison Gloss Vinyl (4ft x 150ft)',
      category: InventoryCategory.ROLL_FEET,
      unit: InventoryUnit.ROLL,
      currentStock: 3.0, // Low stock!
      minStockAlert: 6.0,
      costPrice: 3400.0,
      sellingPrice: 5100.0,
      supplierName: 'Sign Graphics World'
    }
  });

  const acpSheets = await prisma.inventoryItem.create({
    data: {
      name: 'Aludecor ACP Sheet 3mm (8ft x 4ft Deep Blue)',
      category: InventoryCategory.ACRYLIC_SHEET,
      unit: InventoryUnit.PIECE,
      currentStock: 22.0,
      minStockAlert: 8.0,
      costPrice: 1650.0,
      sellingPrice: 2200.0,
      supplierName: 'Aludecor Panels'
    }
  });

  const ledModules = await prisma.inventoryItem.create({
    data: {
      name: 'Samsung 3-LED Injection Module 1.2W Cool White',
      category: InventoryCategory.LED_MODULE,
      unit: InventoryUnit.PIECE,
      currentStock: 120.0, // Low stock alert trigger
      minStockAlert: 300.0,
      costPrice: 18.0,
      sellingPrice: 28.0,
      supplierName: 'Apex LED Lighting Corp'
    }
  });

  const smpsPower = await prisma.inventoryItem.create({
    data: {
      name: 'MeanWell 12V 33A 400W Rainproof SMPS',
      category: InventoryCategory.SMPS_POWER,
      unit: InventoryUnit.PIECE,
      currentStock: 18.0,
      minStockAlert: 5.0,
      costPrice: 1150.0,
      sellingPrice: 1600.0,
      supplierName: 'MeanWell India Power'
    }
  });

  const msPipe = await prisma.inventoryItem.create({
    data: {
      name: 'Apollo MS Square Pipe 1" x 1" 18-Gauge (20ft length)',
      category: InventoryCategory.MS_PIPE,
      unit: InventoryUnit.PIECE,
      currentStock: 45.0,
      minStockAlert: 15.0,
      costPrice: 320.0,
      sellingPrice: 480.0,
      supplierName: 'Apollo Steel Tube Depot'
    }
  });

  // Stock transactions
  await prisma.stockTransaction.create({
    data: {
      inventoryItemId: vinylRoll.id,
      type: StockTransactionType.STOCK_OUT,
      quantity: 2.0,
      performedById: designerOperator.id,
      reason: 'Used for Retail fashion showroom side banner printing'
    }
  });

  // 6. Site Visits & Smart Measurements
  console.log('Seeding Site Visits, Measurements & Technical Checklists...');
  const siteVisit1 = await prisma.siteVisit.create({
    data: {
      customerId: customer1.id,
      assignedToId: fieldBoy.id,
      visitDateTime: new Date(),
      status: SiteVisitStatus.SUBMITTED,
      siteAddress: customer1.address,
      latitude: customer1.latitude,
      longitude: customer1.longitude,
      notes: 'Store entrance facade measurement and structural inspection.'
    }
  });

  // Board 1: 15ft x 4ft = 60 Sq.Ft (5.574 Sq.M)
  const measurement1 = await prisma.measurement.create({
    data: {
      siteVisitId: siteVisit1.id,
      boardName: 'Main Facade LED Board',
      lengthFeet: 15.0,
      heightFeet: 4.0,
      squareFeet: 60.0,
      squareMeters: 60.0 * 0.092903,
      materialType: 'ACP Sheet & Acrylic LED 3D Letters',
      pipeGauge: '1.5" x 1.5" 16 Gauge MS',
      framingType: 'Heavy Duty MS Frame with Primer',
      notes: 'High visibility from main road.'
    }
  });

  // Board 2: 6ft x 3ft = 18 Sq.Ft (1.672 Sq.M)
  const measurement2 = await prisma.measurement.create({
    data: {
      siteVisitId: siteVisit1.id,
      boardName: 'Side Entrance Glow Sign',
      lengthFeet: 6.0,
      heightFeet: 3.0,
      squareFeet: 18.0,
      squareMeters: 18.0 * 0.092903,
      materialType: 'Star Flex Backlit Box',
      pipeGauge: '1" x 1" 18 Gauge MS',
      framingType: 'Backlit Box 9 inch depth'
    }
  });

  await prisma.technicalChecklist.create({
    data: {
      siteVisitId: siteVisit1.id,
      boardFloorHeight: '1st Floor Facade (14 feet from ground)',
      powerSupplyDistanceFeet: 12.0,
      ladderRequired: true,
      craneRequired: false,
      scaffoldingRequired: true,
      obstacles: 'Tree branch on left corner requires pruning prior to installation.',
      notes: 'Main power switch located inside security control room.'
    }
  });

  await prisma.siteMedia.createMany({
    data: [
      {
        siteVisitId: siteVisit1.id,
        mediaType: 'PHOTO',
        fileUrl: 'https://images.unsplash.com/photo-1541888946425-d0fbb18015f6?w=800',
        metadata: JSON.stringify({ description: 'Original site facade photograph' })
      },
      {
        siteVisitId: siteVisit1.id,
        mediaType: 'ANNOTATED_PHOTO',
        fileUrl: 'https://images.unsplash.com/photo-1541888946425-d0fbb18015f6?w=800',
        metadata: JSON.stringify({
          annotations: [
            { type: 'dimension', text: '15.0 ft Width', x1: 50, y1: 100, x2: 350, y2: 100 },
            { type: 'dimension', text: '4.0 ft Height', x1: 350, y1: 100, x2: 350, y2: 220 },
            { type: 'callout', text: 'Power Point 12ft away', x: 200, y: 240 }
          ]
        })
      },
      {
        siteVisitId: siteVisit1.id,
        mediaType: 'VIDEO',
        fileUrl: 'https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_1mb.mp4',
        durationSeconds: 10
      }
    ]
  });

  // 7. Job Cards (Workflow Lifecycle)
  console.log('Seeding Job Cards across Workflow Stages...');
  
  // Job 1: In Fabrication stage
  const job1 = await prisma.jobCard.create({
    data: {
      jobCode: 'JB-2026-0001',
      customerId: customer1.id,
      siteVisitId: siteVisit1.id,
      boardType: 'Acrylic LED 3D Letter ACP Board',
      currentStage: JobStage.FABRICATION,
      status: JobStatus.ACTIVE,
      deadline: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000),
      assignedOperatorId: designerOperator.id,
      assignedInstallerId: installer.id,
      totalSqFt: 78.0,
      totalAmount: 38500.0,
      pendingAmount: 18500.0,
      notes: 'Customer requested 5000K warm white LED letters with blue ACP background.'
    }
  });

  // Associate measurements to Job 1
  await prisma.measurement.update({
    where: { id: measurement1.id },
    data: { jobId: job1.id }
  });
  await prisma.measurement.update({
    where: { id: measurement2.id },
    data: { jobId: job1.id }
  });

  // Stage histories
  await prisma.jobStageHistory.createMany({
    data: [
      {
        jobId: job1.id,
        stage: JobStage.SITE_VISIT,
        status: 'COMPLETED',
        updatedById: fieldBoy.id,
        completedAt: new Date(Date.now() - 48 * 3600 * 1000),
        remarks: 'Site measurements and photo annotations uploaded successfully.'
      },
      {
        jobId: job1.id,
        stage: JobStage.DESIGN_FINAL,
        status: 'COMPLETED',
        updatedById: designerOperator.id,
        completedAt: new Date(Date.now() - 24 * 3600 * 1000),
        remarks: 'Customer approved CDR/PDF vector proof version 2.'
      },
      {
        jobId: job1.id,
        stage: JobStage.PRINTING,
        status: 'COMPLETED',
        updatedById: designerOperator.id,
        completedAt: new Date(Date.now() - 12 * 3600 * 1000),
        remarks: 'Eco-solvent UV printable vinyl printed and laminated.'
      },
      {
        jobId: job1.id,
        stage: JobStage.FABRICATION,
        status: 'IN_PROGRESS',
        updatedById: designerOperator.id,
        completedAt: new Date(),
        remarks: 'CNC cutting complete, assembling 3D acrylic letters and MS frame.'
      }
    ]
  });

  // Design file for Job 1
  await prisma.designFile.create({
    data: {
      jobId: job1.id,
      uploadedById: designerOperator.id,
      fileName: 'Apex_Store_Main_Board_Final_Proof_v2.pdf',
      fileUrl: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
      fileSizeBytes: 4250000,
      version: 2,
      approvalStatus: 'APPROVED',
      customerFeedback: 'Approved on WhatsApp by Sunil Mehta.'
    }
  });

  // Job 2: Completed / Delivered Job with Feedback & Signature
  const job2 = await prisma.jobCard.create({
    data: {
      jobCode: 'JB-2026-0002',
      customerId: customer2.id,
      boardType: 'Hospital Emergency Glow Sign 24x7',
      currentStage: JobStage.DELIVERED,
      status: JobStatus.COMPLETED,
      assignedOperatorId: designerOperator.id,
      assignedInstallerId: installer.id,
      totalSqFt: 40.0,
      totalAmount: 18000.0,
      pendingAmount: 0.0,
      notes: 'Delivered and tested on site with emergency power backup.'
    }
  });

  await prisma.jobStageHistory.createMany({
    data: [
      {
        jobId: job2.id,
        stage: JobStage.SITE_VISIT,
        updatedById: fieldBoy.id,
        completedAt: new Date(Date.now() - 96 * 3600 * 1000)
      },
      {
        jobId: job2.id,
        stage: JobStage.DESIGN_FINAL,
        updatedById: designerOperator.id,
        completedAt: new Date(Date.now() - 72 * 3600 * 1000)
      },
      {
        jobId: job2.id,
        stage: JobStage.PRINTING,
        updatedById: designerOperator.id,
        completedAt: new Date(Date.now() - 48 * 3600 * 1000)
      },
      {
        jobId: job2.id,
        stage: JobStage.FABRICATION,
        updatedById: designerOperator.id,
        completedAt: new Date(Date.now() - 36 * 3600 * 1000)
      },
      {
        jobId: job2.id,
        stage: JobStage.INSTALLATION,
        updatedById: installer.id,
        completedAt: new Date(Date.now() - 24 * 3600 * 1000)
      },
      {
        jobId: job2.id,
        stage: JobStage.DELIVERED,
        updatedById: installer.id,
        completedAt: new Date(Date.now() - 20 * 3600 * 1000),
        remarks: 'Installed successfully with client digital sign-off and 5-star rating.'
      }
    ]
  });

  // Customer Feedback & Digital Signature for Job 2
  await prisma.customerFeedback.create({
    data: {
      jobId: job2.id,
      customerId: customer2.id,
      starRating: 5,
      feedbackText: 'Super fast installation! Glow sign looks extremely vibrant and visible from 200m away.',
      signatureUrl: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
      submittedAt: new Date(Date.now() - 20 * 3600 * 1000)
    }
  });

  // 8. Daily Production Reports (DPR)
  console.log('Seeding Daily Production Reports (DPR)...');
  await prisma.dailyProductionReport.createMany({
    data: [
      {
        operatorId: designerOperator.id,
        machineId: ecoSolventMachine.id,
        jobId: job1.id,
        printedSqFt: 180.0,
        materialUsed: 'Avery Gloss Vinyl + Cold Lamination',
        wasteSqFt: 5.0,
        remarks: 'Clean roll alignment, no head strike.'
      },
      {
        operatorId: designerOperator.id,
        machineId: uvMachine.id,
        jobId: job1.id,
        printedSqFt: 65.0,
        materialUsed: 'Acrylic Sheet Direct UV Print',
        wasteSqFt: 2.0,
        remarks: 'Double-strike white backing for LED illumination.'
      },
      {
        operatorId: designerOperator.id,
        machineId: solventMachine.id,
        jobId: job2.id,
        printedSqFt: 420.0,
        materialUsed: 'Star Flex 440 GSM Backlit',
        wasteSqFt: 12.0,
        remarks: 'High speed production run.'
      }
    ]
  });

  // 9. Quotations & GST Invoices
  console.log('Seeding Quotations, GST Invoices and Payments...');
  const quote1 = await prisma.quotation.create({
    data: {
      quoteNumber: 'QT-2026-0001',
      customerId: customer1.id,
      jobId: job1.id,
      isGst: true,
      subtotalAmount: 30000.0,
      framingCharges: 2500.0,
      installationCharges: 2500.0,
      gstPercentage: 18.0,
      gstAmount: 6300.0,
      discountAmount: 2800.0,
      totalAmount: 38500.0,
      status: QuotationStatus.CONVERTED,
      termsAndConditions: 'Standard 50% advance, balance on delivery.'
    }
  });

  await prisma.quotationItem.createMany({
    data: [
      {
        quotationId: quote1.id,
        itemDescription: 'Main Facade 3D Acrylic LED Letter ACP Board (15ft x 4ft)',
        lengthFeet: 15.0,
        heightFeet: 4.0,
        totalSqFt: 60.0,
        unitRate: 400.0,
        amount: 24000.0,
        materialType: 'ACP Cladding + Acrylic 3D'
      },
      {
        quotationId: quote1.id,
        itemDescription: 'Side Entrance Backlit Glow Sign Box (6ft x 3ft)',
        lengthFeet: 6.0,
        heightFeet: 3.0,
        totalSqFt: 18.0,
        unitRate: 333.33,
        amount: 6000.0,
        materialType: 'Star Flex Backlit'
      }
    ]
  });

  const invoice1 = await prisma.invoice.create({
    data: {
      invoiceNumber: 'INV-2026-0001',
      quotationId: quote1.id,
      customerId: customer1.id,
      jobId: job1.id,
      isGst: true,
      subtotalAmount: 30000.0,
      framingCharges: 2500.0,
      installationCharges: 2500.0,
      gstPercentage: 18.0,
      gstAmount: 6300.0,
      discountAmount: 2800.0,
      totalAmount: 38500.0,
      paidAmount: 20000.0,
      pendingBalance: 18500.0,
      status: InvoiceStatus.PARTIALLY_PAID,
      dueDate: new Date(Date.now() + 7 * 24 * 3600 * 1000)
    }
  });

  await prisma.invoiceItem.createMany({
    data: [
      {
        invoiceId: invoice1.id,
        itemDescription: 'Main Facade 3D Acrylic LED Letter ACP Board (60 Sq.Ft)',
        totalSqFt: 60.0,
        unitRate: 400.0,
        amount: 24000.0
      },
      {
        invoiceId: invoice1.id,
        itemDescription: 'Side Entrance Backlit Glow Sign Box (18 Sq.Ft)',
        totalSqFt: 18.0,
        unitRate: 333.33,
        amount: 6000.0
      }
    ]
  });

  // Advance Payment
  await prisma.payment.create({
    data: {
      invoiceId: invoice1.id,
      customerId: customer1.id,
      amountPaid: 20000.0,
      paymentMethod: PaymentMethod.UPI,
      referenceNumber: 'UPI/623409182390/HDFC',
      receivedById: superAdmin.id,
      notes: '50% Advance received via UPI'
    }
  });

  // 10. Petty Cash Site Expenses
  console.log('Seeding Petty Cash Expenses...');
  await prisma.pettyCashExpense.createMany({
    data: [
      {
        jobId: job1.id,
        employeeId: installer.id,
        category: 'SCREWS',
        amount: 350.0,
        description: 'Heavy duty anchor bolts (3 inch) and stainless steel self-drilling screws',
        status: 'APPROVED',
        approvedById: superAdmin.id
      },
      {
        jobId: job1.id,
        employeeId: installer.id,
        category: 'TEMPO_RENTAL',
        amount: 1200.0,
        description: 'Mini tempo transport from workshop to Grand Galleria Mall',
        status: 'PENDING'
      }
    ]
  });

  // 11. Attendance & Geofencing
  console.log('Seeding Attendance Records...');
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  await prisma.attendance.createMany({
    data: [
      {
        userId: superAdmin.id,
        date: today,
        checkInTime: new Date(today.getTime() + 9 * 3600 * 1000), // 9:00 AM
        status: AttendanceStatus.PRESENT,
        method: AttendanceMethod.QR_SCAN,
        checkInLat: 19.0760,
        checkInLng: 72.8777,
        isVerified: true
      },
      {
        userId: fieldBoy.id,
        date: today,
        checkInTime: new Date(today.getTime() + 9 * 3600 * 1000 + 15 * 60 * 1000), // 9:15 AM
        status: AttendanceStatus.PRESENT,
        method: AttendanceMethod.GEOFENCE_GPS,
        checkInLat: 19.0761,
        checkInLng: 72.8778,
        isVerified: true
      },
      {
        userId: designerOperator.id,
        date: today,
        checkInTime: new Date(today.getTime() + 9 * 3600 * 1000 + 5 * 60 * 1000), // 9:05 AM
        status: AttendanceStatus.PRESENT,
        method: AttendanceMethod.SELFIE,
        checkInLat: 19.0759,
        checkInLng: 72.8776,
        selfieUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300',
        isVerified: true
      },
      {
        userId: installer.id,
        date: today,
        checkInTime: new Date(today.getTime() + 9 * 3600 * 1000 + 45 * 60 * 1000), // 9:45 AM (Late)
        status: AttendanceStatus.LATE,
        method: AttendanceMethod.GEOFENCE_GPS,
        checkInLat: 19.0760,
        checkInLng: 72.8777,
        isVerified: true,
        notes: 'Traffic delay on Western Express Highway'
      }
    ]
  });

  // 12. Gamification, Reward Points & Leaderboard
  console.log('Seeding Rewards & Monthly Leaderboard...');
  await prisma.rewardPoint.createMany({
    data: [
      {
        userId: designerOperator.id,
        points: 100,
        category: RewardCategory.ZERO_WASTE,
        remarks: 'Zero waste on 3D Acrylic Letter CNC cutting batch'
      },
      {
        userId: designerOperator.id,
        points: 150,
        category: RewardCategory.PRODUCTION_100SQFT,
        remarks: 'Achieved 420 Sq.Ft solvent printing in a single shift'
      },
      {
        userId: installer.id,
        points: 150,
        category: RewardCategory.FIVE_STAR_RATING,
        remarks: '5-Star rating from CarePlus Hospital for emergency glow sign'
      },
      {
        userId: fieldBoy.id,
        points: 80,
        category: RewardCategory.TIMELY_INSTALLATION,
        remarks: 'Completed 3 detailed site visits with annotations before deadline'
      }
    ]
  });

  await prisma.leaderboardMonth.createMany({
    data: [
      {
        monthYear: '2026-08',
        userId: designerOperator.id,
        totalPoints: 250,
        rank: 1,
        totalProductionSqFt: 665.0,
        isEmployeeOfMonth: true,
        rewardBonusAmount: 3000.0
      },
      {
        monthYear: '2026-08',
        userId: installer.id,
        totalPoints: 150,
        rank: 2,
        totalProductionSqFt: 0.0,
        isEmployeeOfMonth: false,
        rewardBonusAmount: 0.0
      },
      {
        monthYear: '2026-08',
        userId: fieldBoy.id,
        totalPoints: 80,
        rank: 3,
        totalProductionSqFt: 0.0,
        isEmployeeOfMonth: false,
        rewardBonusAmount: 0.0
      }
    ]
  });

  // 13. Notifications & Audit Logs
  console.log('Seeding Notifications & Audit Logs...');
  await prisma.notification.createMany({
    data: [
      {
        userId: superAdmin.id,
        title: '⚠️ Low Stock Alert: Avery Vinyl Roll',
        message: 'Avery Gloss Vinyl stock is down to 3 rolls (Minimum threshold: 6 rolls). Reorder recommended.',
        type: 'LOW_STOCK',
        channel: 'IN_APP'
      },
      {
        userId: fieldBoy.id,
        title: '📋 New Site Visit Assigned',
        message: 'You have been assigned a site visit for Apex Retail Fashion Store at Andheri West.',
        type: 'TASK_ASSIGNED',
        channel: 'IN_APP'
      },
      {
        userId: designerOperator.id,
        title: '🏆 Employee of the Month Leader!',
        message: 'Congratulations! You are currently Rank #1 on the August 2026 Leaderboard with 250 points.',
        type: 'LEADERBOARD',
        channel: 'IN_APP'
      }
    ]
  });

  await prisma.auditLog.create({
    data: {
      userId: superAdmin.id,
      action: 'SYSTEM_INITIALIZATION',
      entity: 'System',
      entityId: 'ROOT',
      changesPayload: JSON.stringify({ message: 'Seeded initial business catalog, machines, inventory, and users.' })
    }
  });

  console.log('--- Database Seeding Completed Successfully ---');
}

main()
  .catch((e) => {
    console.error('Error during database seed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
