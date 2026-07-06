import SwiftUI

@MainActor
class CodeSharingViewModel: ObservableObject {
    @Published var sharedCodes: [SharedCode] = []
    @Published var isLoading: Bool = false
    @Published var searchText: String = ""
    @Published var selectedCategory: Category = .all

    enum Category: String, CaseIterable, Identifiable {
        case all = "全部"
        case algorithms = "算法"
        case automation = "自动化"
        case data = "数据处理"
        case games = "游戏"
        case utilities = "工具"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .algorithms: return "function"
            case .automation: return "gearshape.2"
            case .data: return "chart.bar"
            case .games: return "gamecontroller"
            case .utilities: return "wrench.and.screwdriver"
            }
        }
    }

    var filteredCodes: [SharedCode] {
        var result = sharedCodes

        if selectedCategory != .all {
            result = result.filter { $0.category == selectedCategory.rawValue }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    init() {
        loadSampleData()
    }

    private func loadSampleData() {
        sharedCodes = [
            SharedCode(
                id: "1",
                title: "斐波那契数列",
                description: "多种方式实现斐波那契数列，包含递归、迭代和矩阵快速幂",
                code: """
                def fib_recursive(n):
                    if n <= 1:
                        return n
                    return fib_recursive(n-1) + fib_recursive(n-2)

                def fib_iterative(n):
                    if n <= 1:
                        return n
                    a, b = 0, 1
                    for _ in range(n-1):
                        a, b = b, a + b
                    return b

                def fib_matrix(n):
                    if n <= 1:
                        return n
                    M = [[1, 1], [1, 0]]
                    def multiply(A, B):
                        return [[A[0][0]*B[0][0] + A[0][1]*B[1][0],
                                 A[0][0]*B[0][1] + A[0][1]*B[1][1]],
                                [A[1][0]*B[0][0] + A[1][1]*B[1][0],
                                 A[1][0]*B[0][1] + A[1][1]*B[1][1]]]
                    def power(M, p):
                        result = [[1, 0], [0, 1]]
                        while p:
                            if p & 1:
                                result = multiply(result, M)
                            M = multiply(M, M)
                            p >>= 1
                        return result
                    result = power(M, n-1)
                    return result[0][0]
                """,
                author: "PyBox Team",
                category: "算法",
                downloads: 128,
                likes: 45,
                createdAt: Date()
            ),
            SharedCode(
                id: "2",
                title: "文件批量重命名",
                description: "支持按前缀、后缀、替换、正则多种模式批量重命名文件",
                code: """
                import os
                import re

                def batch_rename(directory, pattern, replacement, use_regex=False):
                    renamed = []
                    for filename in os.listdir(directory):
                        if use_regex:
                            new_name = re.sub(pattern, replacement, filename)
                        else:
                            new_name = filename.replace(pattern, replacement)
                        if new_name != filename:
                            src = os.path.join(directory, filename)
                            dst = os.path.join(directory, new_name)
                            os.rename(src, dst)
                            renamed.append((filename, new_name))
                    return renamed

                def rename_with_prefix(directory, prefix):
                    return batch_rename(directory, "", prefix)

                def rename_with_counter(directory, start=1, padding=3):
                    files = sorted(os.listdir(directory))
                    renamed = []
                    for i, filename in enumerate(files):
                        ext = os.path.splitext(filename)[1]
                        new_name = f"{start+i:0{padding}d}{ext}"
                        os.rename(
                            os.path.join(directory, filename),
                            os.path.join(directory, new_name)
                        )
                        renamed.append((filename, new_name))
                    return renamed
                """,
                author: "Pythonista",
                category: "工具",
                downloads: 89,
                likes: 32,
                createdAt: Date().addingTimeInterval(-86400)
            ),
            SharedCode(
                id: "3",
                title: "爬虫入门 - 抓取网页图片",
                description: "使用 requests 和正则表达式抓取网页中的图片链接",
                code: """
                import requests
                import re
                import os
                from urllib.parse import urljoin

                def extract_image_urls(html, base_url):
                    pattern = r'<img[^>]+src=["\']([^"\']+)["\']'
                    urls = re.findall(pattern, html)
                    return [urljoin(base_url, url) for url in urls]

                def download_images(url, save_dir="images", max_count=10):
                    os.makedirs(save_dir, exist_ok=True)
                    response = requests.get(url, timeout=10)
                    response.raise_for_status()

                    image_urls = extract_image_urls(response.text, url)[:max_count]
                    downloaded = []

                    for i, img_url in enumerate(image_urls):
                        try:
                            img_data = requests.get(img_url, timeout=10).content
                            ext = os.path.splitext(img_url)[1] or ".jpg"
                            filepath = os.path.join(save_dir, f"image_{i}{ext}")
                            with open(filepath, "wb") as f:
                                f.write(img_data)
                            downloaded.append(filepath)
                        except Exception as e:
                            print(f"Failed to download {img_url}: {e}")

                    return downloaded
                """,
                author: "WebMaster",
                category: "数据处理",
                downloads: 256,
                likes: 78,
                createdAt: Date().addingTimeInterval(-172800)
            ),
            SharedCode(
                id: "4",
                title: "2048 游戏控制台版",
                description: "经典的 2048 游戏终端版本，支持方向键操作",
                code: """
                import random
                import os

                def new_game():
                    grid = [[0]*4 for _ in range(4)]
                    add_random_tile(grid)
                    add_random_tile(grid)
                    return grid

                def add_random_tile(grid):
                    empty = [(i, j) for i in range(4) for j in range(4) if grid[i][j] == 0]
                    if empty:
                        i, j = random.choice(empty)
                        grid[i][j] = 4 if random.random() < 0.1 else 2

                def compress(grid):
                    new_grid = []
                    for row in grid:
                        new_row = [x for x in row if x != 0]
                        new_row += [0] * (4 - len(new_row))
                        new_grid.append(new_row)
                    return new_grid

                def merge(grid):
                    for i in range(4):
                        for j in range(3):
                            if grid[i][j] == grid[i][j+1] and grid[i][j] != 0:
                                grid[i][j] *= 2
                                grid[i][j+1] = 0
                    return grid

                def invert(grid):
                    return [row[::-1] for row in grid]

                def transpose(grid):
                    return [[grid[j][i] for j in range(4)] for i in range(4)]

                def left(grid):
                    grid[:] = compress(grid)
                    grid[:] = merge(grid)
                    grid[:] = compress(grid)

                def right(grid):
                    grid[:] = invert(grid)
                    left(grid)
                    grid[:] = invert(grid)

                def up(grid):
                    grid[:] = transpose(grid)
                    left(grid)
                    grid[:] = transpose(grid)

                def down(grid):
                    grid[:] = transpose(grid)
                    right(grid)
                    grid[:] = transpose(grid)

                def print_grid(grid):
                    os.system('clear')
                    print("=" * 21)
                    for row in grid:
                        print("|" + "".join(f"{x:5}" for x in row) + "|")
                    print("=" * 21)

                def main():
                    grid = new_game()
                    moves = {'a': left, 'd': right, 'w': up, 's': down}

                    while True:
                        print_grid(grid)
                        move = input("Move (w/a/s/d/q): ").lower()
                        if move == 'q':
                            break
                        if move in moves:
                            old = [row[:] for row in grid]
                            moves[move](grid)
                            if grid != old:
                                add_random_tile(grid)
                        else:
                            print("Invalid move")
                """,
                author: "GameDev",
                category: "游戏",
                downloads: 167,
                likes: 55,
                createdAt: Date().addingTimeInterval(-259200)
            )
        ]
    }

    func shareCode(title: String, description: String, code: String, category: String) {
        let newCode = SharedCode(
            id: UUID().uuidString,
            title: title,
            description: description,
            code: code,
            author: "Me",
            category: category,
            downloads: 0,
            likes: 0,
            createdAt: Date()
        )
        sharedCodes.insert(newCode, at: 0)
    }

    func likeCode(_ code: SharedCode) {
        if let index = sharedCodes.firstIndex(where: { $0.id == code.id }) {
            sharedCodes[index].likes += 1
        }
    }
}

struct SharedCode: Identifiable {
    let id: String
    let title: String
    let description: String
    let code: String
    let author: String
    let category: String
    var downloads: Int
    var likes: Int
    let createdAt: Date
}
