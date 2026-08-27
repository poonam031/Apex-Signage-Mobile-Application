class AppConstants {
  static const String appName = 'Apex Signage';
  static const String apiBaseUrl = 'http://127.0.0.1:5000/api/v1'; // Physical device via adb reverse / localhost

  // Roles
  static const String roleSuperAdmin = 'SUPER_ADMIN';
  static const String roleFieldBoy = 'FIELD_BOY';
  static const String roleDesigner = 'DESIGNER_OPERATOR';
  static const String roleInstaller = 'INSTALLATION_TEAM';

  // Job Stages
  static const List<String> jobStages = [
    'SITE_VISIT',
    'DESIGN_FINAL',
    'PRINTING',
    'FABRICATION',
    'INSTALLATION',
    'DELIVERED',
  ];

  // Material Catalogs
  static const List<String> materialTypes = [
    'ACP Sheet',
    'Acrylic LED Letters',
    'Flex 240 GSM',
    'Star Flex 440 GSM',
    'Blackout Flex',
    'Vinyl with Gloss Lamination',
    'Vinyl on 3mm Sunboard',
    'Vinyl on 5mm Sunboard',
    'One Way Vision Film',
    'Canvas Media',
  ];

  static const List<String> pipeGauges = [
    '1" x 1" (18 Gauge)',
    '1" x 1" (16 Gauge)',
    '1.5" x 1.5" (16 Gauge)',
    '2" x 2" Heavy Duty',
    'None / Not Applicable',
  ];

  static const List<String> machineTypes = [
    'Eco-Solvent',
    'UV Flatbed',
    'Solvent Heavy Duty',
    'CNC Router',
  ];

  static const List<String> pettyCashCategories = [
    'SCREWS',
    'ADHESIVE_FEVICOL',
    'TEMPO_RENTAL',
    'TEA_WATER',
    'HARDWARE_MISC',
    'SITE_MISC',
  ];
}
