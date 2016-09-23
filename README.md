# dimgui_sample
DerelictImguiの使用サンプル

* [D言語でdear imgui (AKA ImGui)](http://qiita.com/ousttrue/items/8dc223ded267edb2e41a)

# 更新履歴
* [20160924].gitignoreに引っかかって登録されていなかかったsubmodules/premake5.exeを追加

# ビルド(Windows10 + visual studio 2015 + dmd + VisualD)
* build_submodules_Win32_Release.batを実行する。glfw3.dllとcimgui.dllが生成される
* dub_generate_visuald.batを実行する。dimgui_sample.slnが生成される
* dimgui_sample.slnをvisual studioで開いてF5

# ライセンス
MIT

# 依存ライブラリ
* glfw
* DerelictImgui
    * cimgui
        * imgui

