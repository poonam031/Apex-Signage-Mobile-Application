import { Injectable } from '@nestjs/common';

export interface AreaCalculationResult {
  lengthFeet: number;
  heightFeet: number;
  squareFeet: number;
  squareMeters: number;
}

export interface QuotationCalculationResult {
  items: Array<{
    itemDescription: string;
    lengthFeet: number;
    heightFeet: number;
    totalSqFt: number;
    unitRate: number;
    amount: number;
  }>;
  subtotalAmount: number;
  framingCharges: number;
  installationCharges: number;
  discountAmount: number;
  taxableAmount: number;
  gstPercentage: number;
  gstAmount: number;
  totalAmount: number;
}

export interface SalaryCalculationResult {
  baseSalary: number;
  workingDays: number;
  presentDays: number;
  dailyRate: number;
  earnedBaseSalary: number;
  lateMarksCount: number;
  latePenalty: number;
  overtimeHours: number;
  overtimeEarnings: number;
  rewardBonus: number;
  deductions: number;
  netSalary: number;
}

@Injectable()
export class CalculationService {
  private readonly SQFT_TO_SQM_FACTOR = 0.092903;
  private readonly EARTH_RADIUS_METERS = 6371000;

  /**
   * Calculates square feet and square meters for a given dimension.
   * Sq.Ft = Length * Height
   * Sq.Meter = Sq.Ft * 0.092903
   */
  calculateArea(lengthFeet: number, heightFeet: number): AreaCalculationResult {
    const squareFeet = Math.round(lengthFeet * heightFeet * 100) / 100;
    const squareMeters = Math.round(squareFeet * this.SQFT_TO_SQM_FACTOR * 1000) / 1000;
    return {
      lengthFeet,
      heightFeet,
      squareFeet,
      squareMeters,
    };
  }

  /**
   * Calculates complete quotation or invoice financial breakdown.
   * Formula: (Sq.Ft * Rate) + Framing + Installation - Discount + GST
   */
  calculateQuotation(
    rawItems: Array<{
      itemDescription: string;
      lengthFeet: number;
      heightFeet: number;
      unitRate: number;
    }>,
    framingCharges: number = 0,
    installationCharges: number = 0,
    discountAmount: number = 0,
    isGst: boolean = true,
    gstPercentage: number = 18.0,
  ): QuotationCalculationResult {
    let subtotalAmount = 0;

    const items = rawItems.map((item) => {
      const area = this.calculateArea(item.lengthFeet, item.heightFeet);
      const amount = Math.round(area.squareFeet * item.unitRate * 100) / 100;
      subtotalAmount += amount;
      return {
        itemDescription: item.itemDescription,
        lengthFeet: item.lengthFeet,
        heightFeet: item.heightFeet,
        totalSqFt: area.squareFeet,
        unitRate: item.unitRate,
        amount,
      };
    });

    subtotalAmount = Math.round(subtotalAmount * 100) / 100;
    const baseWithCharges = subtotalAmount + framingCharges + installationCharges;
    const taxableAmount = Math.max(0, baseWithCharges - discountAmount);
    
    let gstAmount = 0;
    if (isGst) {
      gstAmount = Math.round((taxableAmount * (gstPercentage / 100)) * 100) / 100;
    }

    const totalAmount = Math.round((taxableAmount + gstAmount) * 100) / 100;

    return {
      items,
      subtotalAmount,
      framingCharges,
      installationCharges,
      discountAmount,
      taxableAmount,
      gstPercentage: isGst ? gstPercentage : 0,
      gstAmount,
      totalAmount,
    };
  }

  /**
   * Pending Balance = Total Amount - Paid Amount
   */
  calculatePendingBalance(totalAmount: number, paidAmount: number): number {
    return Math.max(0, Math.round((totalAmount - paidAmount) * 100) / 100);
  }

  /**
   * Calculates geodesic distance between two GPS coordinates using Haversine formula.
   * Returns distance in meters.
   */
  calculateHaversineDistanceMeters(
    lat1: number,
    lon1: number,
    lat2: number,
    lon2: number,
  ): number {
    const toRad = (val: number) => (val * Math.PI) / 180;
    const dLat = toRad(lat2 - lat1);
    const dLon = toRad(lon2 - lon1);
    const radLat1 = toRad(lat1);
    const radLat2 = toRad(lat2);

    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.sin(dLon / 2) * Math.sin(dLon / 2) * Math.cos(radLat1) * Math.cos(radLat2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return Math.round(this.EARTH_RADIUS_METERS * c * 10) / 10;
  }

  /**
   * Checks if user GPS coordinates are within configured geofence radius (e.g. 200 meters)
   */
  isWithinGeofence(
    userLat: number,
    userLon: number,
    shopLat: number,
    shopLon: number,
    radiusMeters: number = 200,
  ): { isWithin: boolean; distanceMeters: number } {
    const distanceMeters = this.calculateHaversineDistanceMeters(userLat, userLon, shopLat, shopLon);
    return {
      isWithin: distanceMeters <= radiusMeters,
      distanceMeters,
    };
  }

  /**
   * Monthly salary calculator considering attendance, late marks, overtime, reward adjustments.
   */
  calculateMonthlySalary(
    baseSalary: number,
    workingDays: number = 30,
    presentDays: number = 30,
    lateMarksCount: number = 0,
    overtimeHours: number = 0,
    overtimeRatePerHour: number = 100,
    rewardBonus: number = 0,
    deductions: number = 0,
  ): SalaryCalculationResult {
    const dailyRate = Math.round((baseSalary / workingDays) * 100) / 100;
    const earnedBaseSalary = Math.round(presentDays * dailyRate * 100) / 100;

    // Rule: Every 3 late marks = 0.5 day salary penalty
    const halfDayPenalties = Math.floor(lateMarksCount / 3);
    const latePenalty = Math.round(halfDayPenalties * (dailyRate / 2) * 100) / 100;

    const overtimeEarnings = Math.round(overtimeHours * overtimeRatePerHour * 100) / 100;
    const netSalary = Math.max(
      0,
      Math.round((earnedBaseSalary - latePenalty + overtimeEarnings + rewardBonus - deductions) * 100) / 100,
    );

    return {
      baseSalary,
      workingDays,
      presentDays,
      dailyRate,
      earnedBaseSalary,
      lateMarksCount,
      latePenalty,
      overtimeHours,
      overtimeEarnings,
      rewardBonus,
      deductions,
      netSalary,
    };
  }
}
