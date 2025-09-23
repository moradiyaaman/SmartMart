import 'package:flutter/material.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final List<Map<String, dynamic>> reviews = [];
  final TextEditingController reviewController = TextEditingController();
  double rating = 0;

  void addReview(String review, double rating) {
    setState(() {
      reviews.add({'review': review, 'rating': rating});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reviews'),
      ),
      body: Column(
        children: [
          Expanded(
            child: reviews.isEmpty
                ? const Center(
                    child: Text('No reviews yet'),
                  )
                : ListView.builder(
                    itemCount: reviews.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(reviews[index]['review']),
                        subtitle: Text('Rating: ${reviews[index]['rating']}'),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: reviewController,
                  decoration: const InputDecoration(labelText: 'Write a review'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('Rating:'),
                    Slider(
                      value: rating,
                      onChanged: (value) {
                        setState(() {
                          rating = value;
                        });
                      },
                      min: 0,
                      max: 5,
                      divisions: 5,
                      label: rating.toString(),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    if (reviewController.text.isNotEmpty) {
                      addReview(reviewController.text, rating);
                      reviewController.clear();
                      setState(() {
                        rating = 0;
                      });
                    }
                  },
                  child: const Text('Submit Review'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
