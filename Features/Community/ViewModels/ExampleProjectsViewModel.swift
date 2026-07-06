import SwiftUI

@MainActor
class ExampleProjectsViewModel: ObservableObject {
    @Published var projects: [ExampleProject] = []

    init() {
        loadProjects()
    }

    private func loadProjects() {
        projects = [
            ExampleProject(
                id: "1",
                name: "待办事项列表",
                description: "学习列表操作、文件存储和基础 CRUD",
                difficulty: .beginner,
                duration: "30 分钟",
                files: [
                    TemplateFile(name: "todo.py", content: """
                    # -*- coding: utf-8 -*-
                    todos = []

                    def show_todos():
                        if not todos:
                            print("No todos yet")
                            return
                        for i, todo in enumerate(todos, 1):
                            print(f"{i}. {todo}")

                    def add_todo(item):
                        todos.append(item)
                        print(f"Added: {item}")

                    def main():
                        while True:
                            print("\\n1. Show todos 2. Add todo 3. Quit")
                            choice = input("Choice: ")
                            if choice == "1":
                                show_todos()
                            elif choice == "2":
                                item = input("Todo: ")
                                add_todo(item)
                            elif choice == "3":
                                break

                    if __name__ == "__main__":
                        main()
                    """)
                ],
                concepts: ["列表", "字典", "JSON", "CRUD"],
                icon: "checkmark.circle"
            ),
            ExampleProject(
                id: "2",
                name: "计算器",
                description: "学习函数定义、异常处理和用户输入",
                difficulty: .beginner,
                duration: "25 分钟",
                files: [
                    TemplateFile(name: "calculator.py", content: """
                    # -*- coding: utf-8 -*-
                    def add(a, b): return a + b
                    def sub(a, b): return a - b
                    def mul(a, b): return a * b
                    def div(a, b):
                        if b == 0: raise ValueError("Div by zero")
                        return a / b

                    ops = {'+': add, '-': sub, '*': mul, '/': div}

                    def calculator():
                        while True:
                            try:
                                a = float(input("A: "))
                                op = input("Op: ")
                                b = float(input("B: "))
                                result = ops[op](a, b)
                                print(f"Result: {result}")
                            except Exception as e:
                                print(f"Error: {e}")
                            if input("Again? (y/n): ").lower() != 'y':
                                break

                    if __name__ == "__main__":
                        calculator()
                    """)
                ],
                concepts: ["函数", "异常处理", "字典映射", "循环"],
                icon: "function"
            ),
            ExampleProject(
                id: "3",
                name: "猜数字游戏",
                description: "学习随机数、循环和条件判断",
                difficulty: .beginner,
                duration: "20 分钟",
                files: [
                    TemplateFile(name: "guess_number.py", content: """
                    # -*- coding: utf-8 -*-
                    import random

                    secret = random.randint(1, 100)
                    attempts = 0
                    max_attempts = 7

                    print("Guess a number 1-100")

                    while attempts < max_attempts:
                        guess = int(input("Your guess: "))
                        attempts += 1
                        if guess == secret:
                            print(f"Correct! {attempts} attempts")
                            break
                        elif guess < secret:
                            print("Too small")
                        else:
                            print("Too big")
                    else:
                        print(f"Game over! It was {secret}")
                    """)
                ],
                concepts: ["随机数", "循环", "条件判断", "异常处理"],
                icon: "gamecontroller"
            ),
            ExampleProject(
                id: "4",
                name: "学生成绩管理",
                description: "学习面向对象编程和数据聚合",
                difficulty: .intermediate,
                duration: "45 分钟",
                files: [
                    TemplateFile(name: "student_manager.py", content: """
                    # -*- coding: utf-8 -*-
                    class Student:
                        def __init__(self, name, scores):
                            self.name = name
                            self.scores = scores

                        @property
                        def average(self):
                            return sum(self.scores) / len(self.scores)

                        def __repr__(self):
                            return f"{self.name}: {self.average:.1f}"

                    class ClassManager:
                        def __init__(self):
                            self.students = []

                        def add(self, name, scores):
                            self.students.append(Student(name, scores))

                        def top(self, n=3):
                            return sorted(self.students, key=lambda s: s.average, reverse=True)[:n]

                    manager = ClassManager()
                    manager.add("Alice", [90, 85, 88])
                    manager.add("Bob", [75, 80, 92])
                    manager.add("Carol", [95, 90, 87])

                    print("All students:")
                    for s in manager.students:
                        print(s)

                    print("\\nTop 2:")
                    for s in manager.top(2):
                        print(s)
                    """)
                ],
                concepts: ["类", "属性", "列表排序", "统计分析"],
                icon: "chart.bar"
            ),
            ExampleProject(
                id: "5",
                name: "天气查询 CLI",
                description: "学习 HTTP 请求和 JSON 解析",
                difficulty: .intermediate,
                duration: "40 分钟",
                files: [
                    TemplateFile(name: "weather.py", content: """
                    # -*- coding: utf-8 -*-
                    import urllib.request
                    import urllib.parse
                    import json

                    def get_weather(city):
                        url = f"https://api.openweathermap.org/data/2.5/weather?q={city}"
                        try:
                            with urllib.request.urlopen(url, timeout=10) as response:
                                data = json.loads(response.read())
                                temp = data['main']['temp']
                                desc = data['weather'][0]['description']
                                print(f"{city}: {temp}°C, {desc}")
                        except Exception as e:
                            print(f"Error: {e}")

                    if __name__ == "__main__":
                        city = input("City: ")
                        get_weather(city)
                    """)
                ],
                concepts: ["HTTP 请求", "JSON", "API", "异常处理"],
                icon: "cloud.sun"
            ),
            ExampleProject(
                id: "6",
                name: "Markdown 转 HTML",
                description: "学习正则表达式和字符串处理",
                difficulty: .advanced,
                duration: "50 分钟",
                files: [
                    TemplateFile(name: "markdown_to_html.py", content: """
                    # -*- coding: utf-8 -*-
                    import re

                    def md_to_html(text):
                        text = re.sub(r'^### (.*)$', r'<h3>\\1</h3>', text)
                        text = re.sub(r'^## (.*)$', r'<h2>\\1</h2>', text)
                        text = re.sub(r'^# (.*)$', r'<h1>\\1</h1>', text)
                        text = re.sub(r'\\*\\*(.*?)\\*\\*', r'<strong>\\1</strong>', text)
                        text = re.sub(r'\\*(.*?)\\*', r'<em>\\1</em>', text)
                        text = re.sub(r'`(.*?)`', r'<code>\\1</code>', text)
                        text = re.sub(r'\\[(.*?)\\]\\((.*?)\\)', r'<a href="\\2">\\1</a>', text)
                        return text

                    md = \"\"\"
                    # Hello
                    This is **bold** and *italic*
                    [Link](http://example.com)
                    \"\"\"

                    print(md_to_html(md))
                    """)
                ],
                concepts: ["正则表达式", "字符串处理", "文件 IO", "状态机"],
                icon: "doc.richtext"
            )
        ]
    }
}

struct ExampleProject: Identifiable {
    let id: String
    let name: String
    let description: String
    let difficulty: Difficulty
    let duration: String
    let files: [TemplateFile]
    let concepts: [String]
    let icon: String

    enum Difficulty: String {
        case beginner = "入门"
        case intermediate = "进阶"
        case advanced = "高级"

        var color: Color {
            switch self {
            case .beginner: return .green
            case .intermediate: return .orange
            case .advanced: return .red
            }
        }
    }
}
