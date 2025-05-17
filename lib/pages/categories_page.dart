// import 'package:flutter/material.dart';
// import 'dart:io';
// import 'package:provider/provider.dart';
// import 'package:surebuy/models/categories_model.dart';
// import 'package:surebuy/providers/admin_provider.dart';
// import 'package:surebuy/services/db_service.dart';
// import 'package:surebuy/services/storage_service.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:surebuy/containers/additional_confirm.dart';

// class CategoriesPage extends StatefulWidget {
//   const CategoriesPage({super.key});

//   @override
//   State<CategoriesPage> createState() => _CategoriesPageState();
// }

// class _CategoriesPageState extends State<CategoriesPage> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Categories"),
//       ),
//       body: Consumer<AdminProvider>(
//         builder: (context, value, child) {
//           List<CategoriesModel> categories =
//               CategoriesModel.fromJsonList(value.categories);

//           if (value.categories.isEmpty) {
//             return const Center(
//               child: Text("No Categories Found"),
//             );
//           }

//           return ListView.builder(
//             itemCount: value.categories.length,
//             itemBuilder: (context, index) {
//               return ListTile(
//                 leading: SizedBox(
//                     height: 50,
//                     width: 50,
//                     child: Image.network(categories[index].image == ""
//                         ? "https://demofree.sirv.com/nope-not-here.jpg"
//                         : categories[index].image)),
//                 onTap: () {
//                   showDialog(
//                       context: context,
//                       builder: (context) => AlertDialog(
//                             title: const Text("What you want to do"),
//                             content:
//                                 const Text("Delete action cannot be undone"),
//                             actions: [
//                               TextButton(
//                                   onPressed: () {
//                                     Navigator.pop(context);
//                                     showDialog(
//                                         context: context,
//                                         builder: (context) => AdditionalConfirm(
//                                             contentText:
//                                                 "Are you sure you want to delete this",
//                                             onYes: () {
//                                               DatabaseService()
//                                                   .deleteCategories(
//                                                       docId:
//                                                           categories[index].id);
//                                               Navigator.pop(context);
//                                             },
//                                             onNo: () {
//                                               Navigator.pop(context);
//                                             }));
//                                   },
//                                   child: const Text("Delete Category")),
//                               TextButton(
//                                   onPressed: () {
//                                     Navigator.pop(context);
//                                     showDialog(
//                                         context: context,
//                                         builder: (context) => ModifyCategory(
//                                               isUpdating: true,
//                                               categoryId: categories[index].id,
//                                               priority:
//                                                   categories[index].priority,
//                                               image: categories[index].image,
//                                               name: categories[index].name,
//                                             ));
//                                   },
//                                   child: const Text("Update Category"))
//                             ],
//                           ));
//                 },
//                 title: Text(
//                   categories[index].name,
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 subtitle: Text("Priority : ${categories[index].priority}"),
//                 trailing: IconButton(
//                   icon: const Icon(Icons.edit_outlined),
//                   onPressed: () {
//                     showDialog(
//                         context: context,
//                         builder: (context) => ModifyCategory(
//                               isUpdating: true,
//                               categoryId: categories[index].id,
//                               priority: categories[index].priority,
//                               image: categories[index].image,
//                               name: categories[index].name,
//                             ));
//                   },
//                 ),
//               );
//             },
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           showDialog(
//               context: context,
//               builder: (context) => const ModifyCategory(
//                     isUpdating: false,
//                     categoryId: "",
//                     priority: 0,
//                   ));
//         },
//         child: const Icon(Icons.add),
//       ),
//     );
//   }
// }

// class ModifyCategory extends StatefulWidget {
//   final bool isUpdating;
//   final String? name;
//   final String categoryId;
//   final String? image;
//   final int priority;
//   const ModifyCategory(
//       {super.key,
//       required this.isUpdating,
//       this.name,
//       required this.categoryId,
//       this.image,
//       required this.priority});

//   @override
//   State<ModifyCategory> createState() => _ModifyCategoryState();
// }

// class _ModifyCategoryState extends State<ModifyCategory> {
//   final formKey = GlobalKey<FormState>();
//   final ImagePicker picker = ImagePicker();
//   late XFile? image;
//   TextEditingController categoryController = TextEditingController();
//   TextEditingController imageController = TextEditingController();
//   TextEditingController priorityController = TextEditingController();

//   @override
//   void initState() {
//     if (widget.isUpdating && widget.name != null) {
//       categoryController.text = widget.name!;
//       imageController.text = widget.image!;
//       priorityController.text = widget.priority.toString();
//     }
//     super.initState();
//   }

//   // NEW : upload to cloudinary
//   //void _pickImageAndCloudinaryUpload() async {
//   //  image = await picker.pickImage(source: ImageSource.gallery);
//   //  if (image != null) {
//   //   String? res = await uploadToCloudinary(image);
//   //   setState(() {
//   //     if (res != null) {
//   //      imageController.text = res;
//   //      print("set image url ${res} : ${imageController.text}");
//   //       ScaffoldMessenger.of(context).showSnackBar(
//   //            const SnackBar(content: Text("Image uploaded successfully")));
//   //     }
//   ///    });
//   //  }
//   /// }

//   // OLD : upload to firebase
//   // function to pick image using image picker
//   Future<void> pickImage() async {
//     image = await picker.pickImage(source: ImageSource.gallery);
//     if (image != null) {
//       String? res = await StorageService().uploadImage(image!.path, context);
//       setState(() {
//         if (res != null) {
//           imageController.text = res;
//           print("set image url $res : ${imageController.text}");
//           ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text("Image uploaded successfully")));
//         }
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: Text(widget.isUpdating ? "Update Category" : "Add Category"),
//       content: SingleChildScrollView(
//         child: Form(
//           key: formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Text("All will be converted to lowercase"),
//               const SizedBox(
//                 height: 10,
//               ),
//               TextFormField(
//                 controller: categoryController,
//                 validator: (v) =>
//                     v!.isEmpty ? "Please enter cataegory name." : null,
//                 decoration: InputDecoration(
//                     hintText: "Category Name",
//                     label: const Text("Category Name"),
//                     fillColor: Colors.deepPurple.shade50,
//                     filled: true),
//               ),
//               const SizedBox(
//                 height: 10,
//               ),
//               const Text("This will be used in ordering categories"),
//               const SizedBox(
//                 height: 10,
//               ),
//               TextFormField(
//                 controller: priorityController,
//                 validator: (v) => v!.isEmpty ? "This cant be empty." : null,
//                 keyboardType: TextInputType.number,
//                 decoration: InputDecoration(
//                     hintText: "Priority",
//                     label: const Text("Priority"),
//                     fillColor: Colors.deepPurple.shade50,
//                     filled: true),
//               ),
//               const SizedBox(
//                 height: 10,
//               ),
//               image == null
//                   ? imageController.text.isNotEmpty
//                       ? Container(
//                           margin: const EdgeInsets.all(20),
//                           height: 100,
//                           width: double.infinity,
//                           color: Colors.deepPurple.shade50,
//                           child: Image.network(
//                             imageController.text,
//                             fit: BoxFit.contain,
//                           ))
//                       : const SizedBox()
//                   : Container(
//                       margin: const EdgeInsets.all(20),
//                       height: 200,
//                       width: double.infinity,
//                       color: Colors.deepPurple.shade50,
//                       child: Image.file(
//                         File(image!.path),
//                         fit: BoxFit.contain,
//                       )),
//               ElevatedButton(
//                   onPressed: () {
//                     // OLD one for firebase storage upload
//                     pickImage();
//                     // NEW for cloudinary Upload
//                     //_pickImageAndCloudinaryUpload();
//                   },
//                   child: const Text("Pick Image")),
//               const SizedBox(
//                 height: 10,
//               ),
//               TextFormField(
//                 controller: imageController,
//                 validator: (v) => v!.isEmpty ? "Please choose an image." : null,
//                 decoration: InputDecoration(
//                     hintText: "Image Link",
//                     label: const Text("Image Link"),
//                     fillColor: Colors.deepPurple.shade50,
//                     filled: true),
//               ),
//             ],
//           ),
//         ),
//       ),
//       actions: [
//         TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//             },
//             child: const Text("Cancel")),
//         TextButton(
//             onPressed: () async {
//               if (formKey.currentState!.validate()) {
//                 if (widget.isUpdating) {
//                   await DatabaseService()
//                       .updateCategories(docId: widget.categoryId, data: {
//                     "name": categoryController.text.toLowerCase(),
//                     "image": imageController.text,
//                     "priority": int.parse(priorityController.text)
//                   });
//                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//                     content: Text("Category Updated"),
//                   ));
//                 } else {
//                   await DatabaseService().createCategories(data: {
//                     "name": categoryController.text.toLowerCase(),
//                     "image": imageController.text,
//                     "priority": int.parse(priorityController.text)
//                   });
//                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//                     content: Text("Category Added"),
//                   ));
//                 }
//                 Navigator.pop(context);
//               }
//             },
//             child: Text(widget.isUpdating ? "Update" : "Add")),
//       ],
//     );
//   }
// }