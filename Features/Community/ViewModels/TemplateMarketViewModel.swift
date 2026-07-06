import SwiftUI

@MainActor
class TemplateMarketViewModel: ObservableObject {
    @Published var templates: [Template] = []
    @Published var searchText: String = ""
    @Published var selectedCategory: Category = .all

    enum Category: String, CaseIterable, Identifiable {
        case all = "全部"
        case starter = "入门项目"
        case automation = "自动化脚本"
        case data = "数据分析"
        case web = "网络应用"
        case game = "游戏开发"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .starter: return "star"
            case .automation: return "gearshape.2"
            case .data: return "chart.bar"
            case .web: return "globe"
            case .game: return "gamecontroller"
            }
        }
    }

    var filteredTemplates: [Template] {
        var result = templates

        if selectedCategory != .all {
            result = result.filter { $0.category == selectedCategory.rawValue }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    init() {
        loadSampleData()
    }

    private func loadSampleData() {
        templates = [
            Template(
                id: "1",
                name: "Python 入门模板",
                description: "包含基础语法、数据类型、控制流程的入门示例，适合第一次学习 Python 的用户",
                category: "入门项目",
                files: [
                    TemplateFile(name: "01_hello.py", content: """
                    # -*- coding: utf-8 -*-
                    \"\"\"
                    PyBox Python 入门示例
                    \"\"\"

                    # 第一个程序
                    print("Hello, PyBox!")
                    print("欢迎来到 Python 世界！")

                    # 变量和数据类型
                    name = "PyBox"
                    version = 1.0
                    is_awesome = True

                    print(f"我是 {name}，版本 {version}")
                    """),
                    TemplateFile(name: "02_variables.py", content: """
                    # -*- coding: utf-8 -*-
                    \"\"\"
                    变量和数据类型
                    \"\"\"

                    # 字符串
                    greeting = "你好"
                    name = 'PyBox'
                    message = '''这是一个
                    多行字符串'''

                    # 数字
                    age = 25
                    price = 19.99
                    is_student = True

                    # 打印
                    print(f"{greeting}，我叫 {name}")
                    print(f"年龄: {age}, 价格: {price}")
                    """),
                    TemplateFile(name: "03_control.py", content: """
                    # -*- coding: utf-8 -*-
                    \"\"\"
                    控制流程
                    \"\"\"

                    # 条件语句
                    score = 85
                    if score >= 90:
                        grade = "A"
                    elif score >= 80:
                        grade = "B"
                    else:
                        grade = "C"
                    print(f"成绩: {grade}")

                    # 循环
                    for i in range(5):
                        print(f"计数: {i}")

                    fruits = ["苹果", "香蕉", "橙子"]
                    for fruit in fruits:
                        print(f"我喜欢吃: {fruit}")
                    """)
                ],
                author: "PyBox Team",
                downloads: 1024,
                rating: 4.8
            ),
            Template(
                id: "2",
                name: "数据处理脚本",
                description: "包含 CSV/JSON 文件读写、数据清洗、简单统计的模板集合",
                category: "数据分析",
                files: [
                    TemplateFile(name: "read_csv.py", content: """
                    # -*- coding: utf-8 -*-
                    import csv
                    import json

                    def read_csv(filepath):
                        \"\"\"读取 CSV 文件\"\"\"
                        data = []
                        with open(filepath, 'r', encoding='utf-8') as f:
                            reader = csv.DictReader(f)
                            for row in reader:
                                data.append(dict(row))
                        return data

                    def read_json(filepath):
                        \"\"\"读取 JSON 文件\"\"\"
                        with open(filepath, 'r', encoding='utf-8') as f:
                            return json.load(f)

                    def write_csv(filepath, data, headers):
                        \"\"\"写入 CSV 文件\"\"\"
                        with open(filepath, 'w', encoding='utf-8', newline='') as f:
                            writer = csv.DictWriter(f, fieldnames=headers)
                            writer.writeheader()
                            writer.writerows(data)

                    def write_json(filepath, data):
                        \"\"\"写入 JSON 文件\"\"\"
                        with open(filepath, 'w', encoding='utf-8') as f:
                            json.dump(data, f, ensure_ascii=False, indent=2)
                    """),
                    TemplateFile(name: "data_cleaning.py", content: """
                    # -*- coding: utf-8 -*-
                    \"\"\"
                    数据清洗工具
                    \"\"\"

                    def remove_nulls(data):
                        \"\"\"移除空值\"\"\"
                        return [row for row in data if all(row.values())]

                    def fill_nulls(data, default=""):
                        \"\"\"填充空值\"\"\"
                        result = []
                        for row in data:
                            filled = {k: (v if v else default) for k, v in row.items()}
                            result.append(filled)
                        return result

                    def deduplicate(data):
                        \"\"\"去重\"\"\"
                        seen = set()
                        result = []
                        for row in data:
                            key = tuple(sorted(row.items()))
                            if key not in seen:
                                seen.add(key)
                                result.append(row)
                        return result
                    """)
                ],
                author: "DataScientist",
                downloads: 756,
                rating: 4.6
            ),
            Template(
                id: "3",
                name: "自动化办公模板",
                description: "文件批量处理、邮件发送、日程管理的自动化脚本模板",
                category: "自动化脚本",
                files: [
                    TemplateFile(name: "batch_rename.py", content: """
                    # -*- coding: utf-8 -*-
                    import os
                    import re

                    def batch_rename(directory, pattern, replacement, use_regex=False):
                        \"\"\"
                        批量重命名文件
                        Args:
                            directory: 目录路径
                            pattern: 要替换的模式
                            replacement: 替换为
                            use_regex: 是否使用正则表达式
                        \"\"\"
                        renamed_files = []
                        for filename in os.listdir(directory):
                            if use_regex:
                                new_name = re.sub(pattern, replacement, filename)
                            else:
                                new_name = filename.replace(pattern, replacement)

                            if new_name != filename:
                                src = os.path.join(directory, filename)
                                dst = os.path.join(directory, new_name)
                                os.rename(src, dst)
                                renamed_files.append((filename, new_name))

                        return renamed_files

                    def add_prefix(directory, prefix):
                        \"\"\"添加前缀\"\"\"
                        return batch_rename(directory, "", prefix)

                    def add_suffix(directory, suffix):
                        \"\"\"添加后缀\"\"\"
                        renamed = []
                        for filename in os.listdir(directory):
                            name, ext = os.path.splitext(filename)
                            new_name = f"{name}{suffix}{ext}"
                            os.rename(
                                os.path.join(directory, filename),
                                os.path.join(directory, new_name)
                            )
                            renamed.append((filename, new_name))
                        return renamed
                    """),
                    TemplateFile(name: "file_organizer.py", content: """
                    # -*- coding: utf-8 -*-
                    import os
                    import shutil

                    EXTENSIONS = {
                        'images': ['.jpg', '.jpeg', '.png', '.gif', '.bmp'],
                        'documents': ['.pdf', '.doc', '.docx', '.txt', '.md'],
                        'archives': ['.zip', '.rar', '.7z', '.tar', '.gz'],
                        'code': ['.py', '.js', '.html', '.css', '.swift'],
                    }

                    def organize_by_extension(directory):
                        \"\"\"按扩展名整理文件\"\"\"
                        for filename in os.listdir(directory):
                            filepath = os.path.join(directory, filename)
                            if os.path.isfile(filepath):
                                ext = os.path.splitext(filename)[1].lower()
                                for category, extensions in EXTENSIONS.items():
                                    if ext in extensions:
                                        target_dir = os.path.join(directory, category)
                                        os.makedirs(target_dir, exist_ok=True)
                                        shutil.move(filepath, os.path.join(target_dir, filename))
                                        break
                    """)
                ],
                author: "AutoMaster",
                downloads: 512,
                rating: 4.5
            ),
            Template(
                id: "4",
                name: "Flappy Bird 游戏",
                description: "经典的 Flappy Bird 小游戏，包含完整的游戏逻辑和碰撞检测",
                category: "游戏开发",
                files: [
                    TemplateFile(name: "flappy_bird.py", content: """
                    # -*- coding: utf-8 -*-
                    \"\"\"
                    Flappy Bird 游戏
                    操控小鸟飞越障碍物
                    \"\"\"

                    import random

                    GRAVITY = 0.5
                    JUMP_STRENGTH = -8
                    PIPE_WIDTH = 60
                    PIPE_GAP = 150
                    PIPE_SPEED = 3

                    class Bird:
                        def __init__(self, x, y):
                            self.x = x
                            self.y = y
                            self.velocity = 0
                            self.radius = 15

                        def jump(self):
                            self.velocity = JUMP_STRENGTH

                        def update(self):
                            self.velocity += GRAVITY
                            self.y += self.velocity

                        def get_rect(self):
                            return {
                                'x': self.x - self.radius,
                                'y': self.y - self.radius,
                                'width': self.radius * 2,
                                'height': self.radius * 2
                            }

                    class Pipe:
                        def __init__(self, x, screen_height):
                            self.x = x
                            self.gap_y = random.randint(100, screen_height - 200)
                            self.width = PIPE_WIDTH
                            self.gap = PIPE_GAP

                        def update(self):
                            self.x -= PIPE_SPEED

                        def get_rects(self):
                            return [
                                {'x': self.x, 'y': 0, 'width': self.width, 'height': self.gap_y},
                                {'x': self.x, 'y': self.gap_y + self.gap,
                                 'width': self.width, 'height': 1000}
                            ]

                    def check_collision(bird, pipes, screen_width, screen_height):
                        bird_rect = bird.get_rect()
                        if bird.y < 0 or bird.y > screen_height:
                            return True

                        for pipe in pipes:
                            for rect in pipe.get_rects():
                                if rect_collision(bird_rect, rect):
                                    return True
                        return False

                    def rect_collision(a, b):
                        return a['x'] < b['x'] + b['width'] and \\
                               a['x'] + a['width'] > b['x'] and \\
                               a['y'] < b['y'] + b['height'] and \\
                               a['y'] + a['height'] > b['y']
                    """)
                ],
                author: "GameDev",
                downloads: 423,
                rating: 4.7
            ),
            Template(
                id: "5",
                name: "REST API 客户端",
                description: "简单的 HTTP 请求封装，支持 GET/POST/PUT/DELETE 方法",
                category: "网络应用",
                files: [
                    TemplateFile(name: "api_client.py", content: """
                    # -*- coding: utf-8 -*-
                    import urllib.request
                    import urllib.parse
                    import json

                    class APIClient:
                        def __init__(self, base_url, headers=None):
                            self.base_url = base_url.rstrip('/')
                            self.headers = headers or {}

                        def _make_request(self, method, endpoint, data=None):
                            url = f"{self.base_url}/{endpoint.lstrip('/')}"
                            body = json.dumps(data).encode('utf-8') if data else None

                            req = urllib.request.Request(
                                url, data=body, method=method, headers=self.headers
                            )
                            req.add_header('Content-Type', 'application/json')

                            with urllib.request.urlopen(req, timeout=30) as response:
                                return json.loads(response.read().decode('utf-8'))

                        def get(self, endpoint, params=None):
                            if params:
                                query = urllib.parse.urlencode(params)
                                endpoint = f"{endpoint}?{query}"
                            return self._make_request('GET', endpoint)

                        def post(self, endpoint, data):
                            return self._make_request('POST', endpoint, data)

                        def put(self, endpoint, data):
                            return self._make_request('PUT', endpoint, data)

                        def delete(self, endpoint):
                            return self._make_request('DELETE', endpoint)
                    """)
                ],
                author: "WebDeveloper",
                downloads: 389,
                rating: 4.4
            )
        ]
    }
}

struct Template: Identifiable {
    let id: String
    let name: String
    let description: String
    let category: String
    let files: [TemplateFile]
    let author: String
    var downloads: Int
    var rating: Double
}

struct TemplateFile: Identifiable {
    var id: String { name }
    let name: String
    let content: String
}
