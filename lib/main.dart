import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Katalog Produk',
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      ),
      home: const ProductListPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

//Data Produk
class Product {
  final int id;
  final String title;
  final String description;
  final double price;
  final double rating;
  final String thumbnail;
  final String category;
  final int stock;
  final String brand;
  final double discountPercentage;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.rating,
    required this.thumbnail,
    required this.category,
    required this.stock,
    required this.brand,
    required this.discountPercentage,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      thumbnail: json['thumbnail'] ?? '',
      category: json['category'] ?? '',
      stock: json['stock'] ?? 0,
      brand: json['brand'] ?? '',
      discountPercentage: (json['discountPercentage'] as num).toDouble(),
    );
  }
}

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  List<Product> products = [];
  List<String> categories = ["Semua Kategori"];
  bool isLoading = true;
  String selectedCategory = "Semua Kategori";
  String searchQuery = "";
  int totalProducts = 0;

  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchProducts();
  }

  //API 1: Fetch Categories
  Future<void> fetchCategories() async {
    try {
      final response = await http.get(Uri.parse('https://dummyjson.com/products/categories'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        List<String> tempCategories = ["Semua Kategori"];
        
        int limitCount = 0;
        for (var item in data) {
          if (limitCount >= 5) break;
          if (item is Map) {
            tempCategories.add(item['slug'] ?? item['name']);
            limitCount++;
          } else if (item is String) {
            tempCategories.add(item);
            limitCount++;
          }
        }
        
        setState(() {
          categories = tempCategories;
        });
      }
    } catch (e) {
      debugPrint("Error fetching categories: $e");
    }
  }

  //API 1: Fetch List Products
  Future<void> fetchProducts() async {
    setState(() {
      isLoading = true;
    });

    try {
      String url = 'https://dummyjson.com/products?limit=8';

      if (searchQuery.isNotEmpty) {
        url = 'https://dummyjson.com/products/search?q=$searchQuery&limit=8';
      } else if (selectedCategory != "Semua Kategori") {
        url = 'https://dummyjson.com/products/category/$selectedCategory?limit=8';
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> productList = data['products'];
        setState(() {
          products = productList.map((item) => Product.fromJson(item)).toList();
          totalProducts = data['total'] ?? products.length;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint("Error fetching products: $e");
    }
  }

  //API 2: Fetch Product Detail by ID
  Future<void> fetchProductDetail(int id) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5))),
    );

    try {
      final response = await http.get(Uri.parse('https://dummyjson.com/products/$id'));
      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        Product detailProduct = Product.fromJson(data);

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => ProductDetailDialog(product: detailProduct),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat detail produk')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = screenWidth > 1100 ? 4 : (screenWidth > 700 ? 3 : (screenWidth > 500 ? 2 : 1));

    return Scaffold(
      body: Column(
        children: [
          //Navbar
          Container(
            color: const Color(0xFF4F46E5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: SafeArea(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DummyStore',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '065124071_Khofivah Destyana Pratiwi',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        onSubmitted: (val) {
                          searchQuery = val.trim();
                          fetchProducts();
                        },
                        decoration: const InputDecoration(
                          hintText: 'Cari produk (contoh: phone, shoes, laptop)...',
                          hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                          prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        CircleAvatar(radius: 4, backgroundColor: Colors.greenAccent),
                        SizedBox(width: 6),
                        Text('API Status: Online', style: TextStyle(color: Colors.white, fontSize: 11)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),

          //Control Panel
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.filter_list, size: 18, color: Colors.indigo),
                    const SizedBox(width: 8),
                    const Text('Kategori: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedCategory,
                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                selectedCategory = newValue;
                                searchQuery = "";
                              });
                              fetchProducts();
                            }
                          },
                          items: categories.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value.toUpperCase()),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'Menampilkan ${products.length} produk (Limit 8)',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 12),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          selectedCategory = "Semua Kategori";
                          searchQuery = "";
                        });
                        fetchProducts();
                      },
                      icon: const Icon(Icons.refresh, size: 16, color: Colors.indigo),
                      label: const Text('Reset Filter', style: TextStyle(fontSize: 13, color: Colors.indigo)),
                    )
                  ],
                )
              ],
            ),
          ),

          //Grid
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
                : products.isEmpty
                    ? const Center(child: Text('Produk tidak ditemukan.'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(24),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.20,
                        ),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          double originalPrice = product.price / (1 - (product.discountPercentage / 100));

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      height: 120,
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(10),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                      ),
                                      child: Image.network(
                                        product.thumbnail,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)
                                          ],
                                        ),
                                        child: Text(
                                          product.category.toUpperCase(),
                                          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                    if (product.discountPercentage > 0)
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEF4444),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '-${product.discountPercentage.round()}%',
                                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              product.brand.isNotEmpty ? product.brand : 'Generic',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              const Icon(Icons.star, color: Colors.amber, size: 12),
                                              const SizedBox(width: 2),
                                              Text(
                                                '${product.rating}',
                                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        product.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        product.description,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '\$${originalPrice.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey,
                                                  decoration: TextDecoration.lineThrough,
                                                ),
                                              ),
                                              Text(
                                                '\$${product.price}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFF4F46E5),
                                                ),
                                              ),
                                            ],
                                          ),
                                          ElevatedButton(
                                            onPressed: () => fetchProductDetail(product.id),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFFEEF2FF),
                                              foregroundColor: const Color(0xFF4F46E5),
                                              elevation: 0,
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                            ),
                                            child: const Row(
                                              children: [
                                                Text('Detail', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                                SizedBox(width: 2),
                                                Icon(Icons.arrow_forward, size: 10),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

//Detail Produk
class ProductDetailDialog extends StatelessWidget {
  final Product product;

  const ProductDetailDialog({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(product.category.toUpperCase(), style: const TextStyle(color: Colors.indigo, fontSize: 11, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            Center(
              child: Image.network(product.thumbnail, height: 160, fit: BoxFit.contain),
            ),
            const SizedBox(height: 16),
            Text(product.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(product.description, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Stok: ${product.stock} unit', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    Text('${product.rating}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                )
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('\$${product.price}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo)),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Tutup'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}