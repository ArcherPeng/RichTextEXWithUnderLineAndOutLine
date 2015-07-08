# RichTextEX支持下划线和描边的版本
这个是LUA版本的，CPP版本的没写，欢迎移植CPP和JS版本  
LUA文件是用一个别人写的文件修改的（添加一些功能，修复几个BUG……话说之前跑都跑不起来啊亲……什么鬼）   
另外抱歉，找不到他的Github链接了……  
***·使用说明看LUA文件里边说的***  
*·TTF字体支持描边，系统字体是不支持的*
## 为了支持描边和下划线还要修改一下Cocos的源码  
UIRichText.h和UIRichText.cpp放到项目源码目录 替换原来的  
路径:frameworks/cocos2d-x/cocos/ui  
另外修改toLua文件  
(修改内容主要三个方面：加入下划线设置，加入描边设置，RichText可以自动更改高度了)
frameworks/cocos2d-x/cocos/scripting/lua-bindings/auto/lua_cocos2dx_ui_auto.cpp  
18878行左右能看到两个函数  
int lua_cocos2dx_ui_RichElementText_init(lua_State* tolua_S)  
和  
int lua_cocos2dx_ui_RichElementText_create(lua_State* tolua_S)  
将这两个函数的实现替换为如下形式：  

    int lua_cocos2dx_ui_RichElementText_init(lua_State* tolua_S)
    {
        int argc = 0;
        cocos2d::ui::RichElementText* cobj = nullptr;
        bool ok  = true;
    
    #if COCOS2D_DEBUG >= 1
        tolua_Error tolua_err;
    #endif
    
    
    #if COCOS2D_DEBUG >= 1
        if (!tolua_isusertype(tolua_S,1,"ccui.RichElementText",0,&tolua_err)) goto tolua_lerror;
    #endif
    
        cobj = (cocos2d::ui::RichElementText*)tolua_tousertype(tolua_S,1,0);
    
    #if COCOS2D_DEBUG >= 1
        if (!cobj) 
        {
            tolua_error(tolua_S,"invalid 'cobj' in function 'lua_cocos2dx_ui_RichElementText_init'", nullptr);
            return 0;
        }
    #endif
    
        argc = lua_gettop(tolua_S)-1;
        if (argc == 8)
        {
            int arg0;
            cocos2d::Color3B arg1;
            uint16_t arg2;
            std::string arg3;
            std::string arg4;
            double arg5;
            int arg6;
            bool arg7;
    
            ok &= luaval_to_int32(tolua_S, 2,(int *)&arg0, "ccui.RichElementText:init");
    
            ok &= luaval_to_color3b(tolua_S, 3, &arg1, "ccui.RichElementText:init");
    
            ok &= luaval_to_uint16(tolua_S, 4,&arg2, "ccui.RichElementText:init");
    
            ok &= luaval_to_std_string(tolua_S, 5,&arg3, "ccui.RichElementText:init");
    
            ok &= luaval_to_std_string(tolua_S, 6,&arg4, "ccui.RichElementText:init");
    
            ok &= luaval_to_number(tolua_S, 7,&arg5, "ccui.RichElementText:init");
            
            ok &= luaval_to_int32(tolua_S, 8,&arg6, "ccui.RichElementText:init");
            
            ok &= luaval_to_boolean(tolua_S, 9,&arg7, "ccui.RichElementText:init");
            if(!ok)
            {
                tolua_error(tolua_S,"invalid arguments in function 'lua_cocos2dx_ui_RichElementText_init'", nullptr);
                return 0;
            }
            bool ret = cobj->init(arg0, arg1, arg2, arg3, arg4, arg5,arg6,arg7);
            tolua_pushboolean(tolua_S,(bool)ret);
            return 1;
        }
        luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d \n", "ccui.RichElementText:init",argc, 6);
        return 0;
    
    #if COCOS2D_DEBUG >= 1
        tolua_lerror:
        tolua_error(tolua_S,"#ferror in function 'lua_cocos2dx_ui_RichElementText_init'.",&tolua_err);
    #endif
    
        return 0;
    }
    int lua_cocos2dx_ui_RichElementText_create(lua_State* tolua_S)
    {
        int argc = 0;
        bool ok  = true;
    
    #if COCOS2D_DEBUG >= 1
        tolua_Error tolua_err;
    #endif
    
    #if COCOS2D_DEBUG >= 1
        if (!tolua_isusertable(tolua_S,1,"ccui.RichElementText",0,&tolua_err)) goto tolua_lerror;
    #endif
    
        argc = lua_gettop(tolua_S) - 1;
    
        if (argc == 6)
        {
            int arg0;
            cocos2d::Color3B arg1;
            uint16_t arg2;
            std::string arg3;
            std::string arg4;
            double arg5;
            ok &= luaval_to_int32(tolua_S, 2,(int *)&arg0, "ccui.RichElementText:create");
            ok &= luaval_to_color3b(tolua_S, 3, &arg1, "ccui.RichElementText:create");
            ok &= luaval_to_uint16(tolua_S, 4,&arg2, "ccui.RichElementText:create");
            ok &= luaval_to_std_string(tolua_S, 5,&arg3, "ccui.RichElementText:create");
            ok &= luaval_to_std_string(tolua_S, 6,&arg4, "ccui.RichElementText:create");
            ok &= luaval_to_number(tolua_S, 7,&arg5, "ccui.RichElementText:create");
            if(!ok)
            {
                tolua_error(tolua_S,"invalid arguments in function 'lua_cocos2dx_ui_RichElementText_create'", nullptr);
                return 0;
            }
            cocos2d::ui::RichElementText* ret = cocos2d::ui::RichElementText::create(arg0, arg1, arg2, arg3, arg4, arg5);
            object_to_luaval<cocos2d::ui::RichElementText>(tolua_S, "ccui.RichElementText",(cocos2d::ui::RichElementText*)ret);
            return 1;
        }
        if (argc == 7)
        {
            int arg0;
            cocos2d::Color3B arg1;
            uint16_t arg2;
            std::string arg3;
            std::string arg4;
            double arg5;
            int arg6;
            ok &= luaval_to_int32(tolua_S, 2,(int *)&arg0, "ccui.RichElementText:create");
            ok &= luaval_to_color3b(tolua_S, 3, &arg1, "ccui.RichElementText:create");
            ok &= luaval_to_uint16(tolua_S, 4,&arg2, "ccui.RichElementText:create");
            ok &= luaval_to_std_string(tolua_S, 5,&arg3, "ccui.RichElementText:create");
            ok &= luaval_to_std_string(tolua_S, 6,&arg4, "ccui.RichElementText:create");
            ok &= luaval_to_number(tolua_S, 7,&arg5, "ccui.RichElementText:create");
            ok &= luaval_to_int32(tolua_S, 8,&arg6, "ccui.RichElementText:create");
            if(!ok)
            {
                tolua_error(tolua_S,"invalid arguments in function 'lua_cocos2dx_ui_RichElementText_create'", nullptr);
                return 0;
            }
            cocos2d::ui::RichElementText* ret = cocos2d::ui::RichElementText::create(arg0, arg1, arg2, arg3, arg4, arg5, arg6);
            object_to_luaval<cocos2d::ui::RichElementText>(tolua_S, "ccui.RichElementText",(cocos2d::ui::RichElementText*)ret);
            return 1;
        }
        if (argc == 8)
        {
            int arg0;
            cocos2d::Color3B arg1;
            uint16_t arg2;
            std::string arg3;
            std::string arg4;
            double arg5;
            int arg6;
            bool arg7;
            ok &= luaval_to_int32(tolua_S, 2,(int *)&arg0, "ccui.RichElementText:create");
            ok &= luaval_to_color3b(tolua_S, 3, &arg1, "ccui.RichElementText:create");
            ok &= luaval_to_uint16(tolua_S, 4,&arg2, "ccui.RichElementText:create");
            ok &= luaval_to_std_string(tolua_S, 5,&arg3, "ccui.RichElementText:create");
            ok &= luaval_to_std_string(tolua_S, 6,&arg4, "ccui.RichElementText:create");
            ok &= luaval_to_number(tolua_S, 7,&arg5, "ccui.RichElementText:create");
            ok &= luaval_to_int32(tolua_S, 8,&arg6, "ccui.RichElementText:create");
            ok &= luaval_to_boolean(tolua_S, 9,&arg7, "ccui.RichElementText:create");
            if(!ok)
            {
                tolua_error(tolua_S,"invalid arguments in function 'lua_cocos2dx_ui_RichElementText_create'", nullptr);
                return 0;
            }
            cocos2d::ui::RichElementText* ret = cocos2d::ui::RichElementText::create(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7);
            object_to_luaval<cocos2d::ui::RichElementText>(tolua_S, "ccui.RichElementText",(cocos2d::ui::RichElementText*)ret);
            return 1;
        }
        luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d\n ", "ccui.RichElementText:create",argc, 6);
        return 0;
    #if COCOS2D_DEBUG >= 1
        tolua_lerror:
        tolua_error(tolua_S,"#ferror in function 'lua_cocos2dx_ui_RichElementText_create'.",&tolua_err);
    #endif
        return 0;
    }  
重新编译一下项目，然后就可以在项目里用了  

另外，下划线实现的非常拙略，如果你有更好的方法一定要告诉我。
欢迎交流QQ:446569365
