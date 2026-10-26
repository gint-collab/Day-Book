/// How the to-do list is presented. [detailed] is the full planner (overview,
/// filters, sorting, due dates and priorities); [simple] is a plain checklist.
enum TodoListStyle {
  detailed('Detailed'),
  simple('Simple');

  const TodoListStyle(this.label);
  final String label;
}
