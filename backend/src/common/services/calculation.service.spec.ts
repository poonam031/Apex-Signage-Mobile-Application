import { CalculationService } from './calculation.service';

describe('CalculationService - Signage Engineering & Financial Engine', () => {
  let service: CalculationService;

  beforeEach(() => {
    service = new CalculationService();
  });

  describe('1. Smart Measurement Area Calculation', () => {
    it('should accurately calculate Sq.Ft and Sq.Meter for 10ft x 5ft board', () => {
      const result = service.calculateArea(10, 5);
      expect(result.lengthFeet).toBe(10);
      expect(result.heightFeet).toBe(5);
      expect(result.squareFeet).toBe(50);
      expect(result.squareMeters).toBeCloseTo(4.645, 3);
    });

    it('should accurately calculate decimal dimensions e.g. 15.5ft x 4.25ft', () => {
      const result = service.calculateArea(15.5, 4.25);
      expect(result.squareFeet).toBe(65.88);
      expect(result.squareMeters).toBeCloseTo(6.12, 2);
    });
  });

  describe('2. Quotation and GST Invoicing Calculation', () => {
    it('should calculate subtotal, framing, installation, GST (18%) and total amount', () => {
      const items = [
        { itemDescription: 'Main LED Board', lengthFeet: 10, heightFeet: 5, unitRate: 400 }, // 50 sqft * 400 = 20,000
        { itemDescription: 'Side Banner', lengthFeet: 6, heightFeet: 3, unitRate: 50 },      // 18 sqft * 50 = 900
      ];
      const framingCharges = 2000;
      const installationCharges = 1500;
      const discount = 400;

      const calc = service.calculateQuotation(items, framingCharges, installationCharges, discount, true, 18);

      expect(calc.subtotalAmount).toBe(20900);
      expect(calc.taxableAmount).toBe(20900 + 2000 + 1500 - 400); // 24,000
      expect(calc.gstAmount).toBe(4320); // 18% of 24,000
      expect(calc.totalAmount).toBe(28320); // 24,000 + 4320
    });

    it('should support Non-GST quotations with 0% tax', () => {
      const items = [{ itemDescription: 'Flex Board', lengthFeet: 10, heightFeet: 2, unitRate: 100 }];
      const calc = service.calculateQuotation(items, 0, 0, 0, false);
      expect(calc.gstAmount).toBe(0);
      expect(calc.totalAmount).toBe(2000);
    });
  });

  describe('3. Pending Balance Calculation', () => {
    it('should calculate pending balance accurately', () => {
      expect(service.calculatePendingBalance(38500, 20000)).toBe(18500);
      expect(service.calculatePendingBalance(38500, 38500)).toBe(0);
      expect(service.calculatePendingBalance(38500, 40000)).toBe(0); // No negative pending balance
    });
  });

  describe('4. Geofencing 200-Meter Haversine Calculation', () => {
    const shopLat = 19.0760;
    const shopLon = 72.8777;

    it('should approve check-in within 200m radius', () => {
      // 50 meters away coordinate
      const userLat = 19.0763;
      const userLon = 72.8779;
      const result = service.isWithinGeofence(userLat, userLon, shopLat, shopLon, 200);
      expect(result.isWithin).toBe(true);
      expect(result.distanceMeters).toBeLessThan(200);
    });

    it('should reject check-in beyond 200m radius', () => {
      // ~1.5 km away coordinate
      const userLat = 19.0900;
      const userLon = 72.8900;
      const result = service.isWithinGeofence(userLat, userLon, shopLat, shopLon, 200);
      expect(result.isWithin).toBe(false);
      expect(result.distanceMeters).toBeGreaterThan(200);
    });
  });

  describe('5. Monthly Salary & Payroll Calculation', () => {
    it('should calculate net salary with late mark deductions and overtime', () => {
      const baseSalary = 30000;
      const workingDays = 30;
      const presentDays = 30;
      const lateMarks = 3; // 3 late marks = 0.5 day penalty (500 Rs)
      const overtimeHours = 10;
      const overtimeRate = 150; // +1500 Rs
      const rewardBonus = 1000; // +1000 Rs
      const deductions = 0;

      const calc = service.calculateMonthlySalary(
        baseSalary,
        workingDays,
        presentDays,
        lateMarks,
        overtimeHours,
        overtimeRate,
        rewardBonus,
        deductions,
      );

      expect(calc.dailyRate).toBe(1000);
      expect(calc.earnedBaseSalary).toBe(30000);
      expect(calc.latePenalty).toBe(500);
      expect(calc.overtimeEarnings).toBe(1500);
      expect(calc.netSalary).toBe(30000 - 500 + 1500 + 1000); // 32,000
    });
  });
});
