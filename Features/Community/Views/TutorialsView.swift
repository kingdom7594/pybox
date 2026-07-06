import SwiftUI

struct TutorialsView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                TutorialSection(title: "入门教程", tutorials: beginnerTutorials)
                TutorialSection(title: "进阶技巧", tutorials: intermediateTutorials)
                TutorialSection(title: "项目实战", tutorials: advancedTutorials)
            }
            .padding(16)
        }
    }
}

struct Tutorial: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let steps: [String]
}

let beginnerTutorials: [Tutorial] = [
    Tutorial(
        id: "1",
        title: "第一个 Python 程序",
        description: "学习如何用 PyBox 运行你的第一行代码",
        icon: "play.circle",
        steps: [
            "1. 打开 PyBox，点击底部「编辑」标签",
            "2. 输入 print('Hello, World!')",
            "3. 点击右上角的运行按钮 ▶",
            "4. 在下方终端看到输出结果"
        ]
    ),
    Tutorial(
        id: "2",
        title: "变量和数据类型",
        description: "了解 Python 中的基本数据类型",
        icon: "number",
        steps: [
            "整数: age = 25",
            "浮点数: price = 19.99",
            "字符串: name = 'Alice'",
            "布尔值: is_student = True",
            "用 type() 函数可以查看变量类型"
        ]
    ),
    Tutorial(
        id: "3",
        title: "条件判断",
        description: "学习 if-elif-else 条件语句",
        icon: "arrow.triangle.branch",
        steps: [
            "if score >= 90:",
            "    grade = 'A'",
            "elif score >= 80:",
            "    grade = 'B'",
            "else:",
            "    grade = 'C'"
        ]
    ),
    Tutorial(
        id: "4",
        title: "循环",
        description: "掌握 for 和 while 循环",
        icon: "repeat",
        steps: [
            "for i in range(5):",
            "    print(i)",
            "",
            "while count < 10:",
            "    count += 1"
        ]
    )
]

let intermediateTutorials: [Tutorial] = [
    Tutorial(
        id: "5",
        title: "列表操作",
        description: "创建、访问、修改列表",
        icon: "list.bullet",
        steps: [
            "创建: fruits = ['苹果', '香蕉']",
            "添加: fruits.append('橙子')",
            "访问: fruits[0]",
            "切片: fruits[1:3]",
            "长度: len(fruits)"
        ]
    ),
    Tutorial(
        id: "6",
        title: "字典",
        description: "键值对数据结构",
        icon: "bookmark",
        steps: [
            "创建: person = {'name': 'Alice', 'age': 25}",
            "访问: person['name']",
            "添加: person['city'] = 'Beijing'",
            "遍历: for key, value in person.items()"
        ]
    ),
    Tutorial(
        id: "7",
        title: "函数定义",
        description: "封装可复用的代码",
        icon: "function",
        steps: [
            "def greet(name):",
            "    return f'Hello, {name}!'",
            "",
            "greet('Alice')  # 调用"
        ]
    ),
    Tutorial(
        id: "8",
        title: "异常处理",
        description: "用 try-except 处理错误",
        icon: "exclamationmark.triangle",
        steps: [
            "try:",
            "    result = 10 / 0",
            "except ZeroDivisionError:",
            "    print('不能除零')"
        ]
    )
]

let advancedTutorials: [Tutorial] = [
    Tutorial(
        id: "9",
        title: "面向对象编程",
        description: "类、对象、继承",
        icon: "cube",
        steps: [
            "class Dog:",
            "    def __init__(self, name):",
            "        self.name = name",
            "    def bark(self):",
            "        print('Wang!')",
            "",
            "my_dog = Dog('旺财')",
            "my_dog.bark()"
        ]
    ),
    Tutorial(
        id: "10",
        title: "文件操作",
        description: "读写文本和 JSON 文件",
        icon: "doc.text",
        steps: [
            "# 读取",
            "with open('file.txt', 'r') as f:",
            "    content = f.read()",
            "",
            "# 写入",
            "with open('output.txt', 'w') as f:",
            "    f.write('Hello')"
        ]
    ),
    Tutorial(
        id: "11",
        title: "使用 pip 安装包",
        description: "扩展 Python 功能",
        icon: "shippingbox",
        steps: [
            "在 PyBox 终端输入:",
            "pip install requests",
            "",
            "然后在代码中:",
            "import requests"
        ]
    )
]

struct TutorialSection: View {
    let title: String
    let tutorials: [Tutorial]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Theme.Colors.textPrimary)

            ForEach(tutorials) { tutorial in
                TutorialCard(tutorial: tutorial)
            }
        }
    }
}

struct TutorialCard: View {
    let tutorial: Tutorial
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: tutorial.icon)
                        .font(.system(size: 20))
                        .foregroundColor(Theme.Colors.accent)
                        .frame(width: 36)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(tutorial.title)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Theme.Colors.textPrimary)

                        Text(tutorial.description)
                            .font(.system(size: 13))
                            .foregroundColor(Theme.Colors.textMuted)
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.textMuted)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(16)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(tutorial.steps, id: \.self) { step in
                        Text(step)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(step.hasPrefix("    ") ? Theme.Colors.textSecondary : Theme.Colors.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .background(Theme.Colors.surface2)
        .cornerRadius(12)
    }
}

#Preview {
    TutorialsView()
        .background(Theme.Colors.background)
}
