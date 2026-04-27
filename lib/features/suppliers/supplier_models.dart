class MockSupplier {
  const MockSupplier({
    required this.id,
    required this.name,
    required this.contact,
    required this.phone,
    required this.email,
    required this.address,
  });

  final String id;
  final String name;
  final String contact;
  final String phone;
  final String email;
  final String address;
}

const kMockSuppliers = [
  MockSupplier(
    id: '1',
    name: 'Distribuidora El Maizal',
    contact: 'Carlos Ríos',
    phone: '0991234567',
    email: 'ventas@elmaizal.ec',
    address: 'Av. Maldonado y Calle Chimborazo, Quito',
  ),
  MockSupplier(
    id: '2',
    name: 'Frutas y Verduras Don Luis',
    contact: 'Luis Herrera',
    phone: '0987654321',
    email: 'donluis@gmail.com',
    address: 'Mercado Mayorista, puesto 45, Quito',
  ),
  MockSupplier(
    id: '3',
    name: 'Mariscos del Pacífico',
    contact: 'Ana Cortez',
    phone: '0978001122',
    email: 'pedidos@mariscospacifico.ec',
    address: 'Calle 10 de Agosto 3341, Guayaquil',
  ),
];
