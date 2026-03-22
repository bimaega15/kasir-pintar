abstract class AppRoutes {
  static const splash = '/splash';
  static const main = '/';
  static const home = '/home';
  static const master = '/master';
  static const report = '/report';
  static const pos = '/pos';
  static const products = '/products';
  static const addEditProduct = '/products/form';
  static const history = '/history';
  static const transactionDetail = '/history/detail';
  static const receipt = '/receipt';
  static const printerSettings = '/printer-settings';
  // v2 — restaurant flow
  static const orderType = '/order/type';
  static const tableSelect = '/order/table-select';
  static const orderConfirm = '/order/confirm';
  static const activeOrders = '/orders/active';
  static const kitchen = '/kitchen';
  static const tables = '/tables';
  static const addEditTable = '/tables/form';
  static const payment = '/payment';
  static const appSettings = '/settings';
  // transaksi tunda
  static const parkedOrders = '/orders/parked';
  // hutang / dp
  static const debtList = '/debts';
  // v3 — shift + void log
  static const openShift = '/shift/open';
  static const closeShift = '/shift/close';
  static const shiftReport = '/shift/report';
  static const voidLog = '/void-log';
  static const voidLogDetail = '/void-log/detail';
  // v4 — auth
  static const login = '/login';
  static const setup = '/setup';
  // master kategori
  static const categories = '/categories';
  static const addEditCategory = '/categories/form';
  // level harga
  static const priceLevels = '/price-levels';
  static const addEditPriceLevel = '/price-levels/form';
  // stok
  static const stockManagement = '/stock-management';
  static const stockCard = '/stock-card';
  static const stockOpname = '/stock-opname';
  static const stockOpnameDetail = '/stock-opname-detail';
  // bahan baku
  static const bahanBaku = '/bahan-baku';
  static const addEditBahanBaku = '/bahan-baku/form';
  static const bahanBakuDetail = '/bahan-baku/detail';
  // laporan detail
  static const salesReport = '/report/sales';
  static const revenueReport = '/report/revenue';
  static const profitLossReport = '/report/profit-loss';
  // pelanggan
  static const customers = '/customers';
  static const addEditCustomer = '/customers/form';
  static const customerDetail = '/customers/detail';
}
