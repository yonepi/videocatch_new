// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require rails-ujs
//= require activestorage
//= require turbolinks
//= require_tree .
//= require jquery
//= require jquery_ujs
//rails5以降にjqueryを使いたい場合には、turbolinksを読み込んだ後に、jquery読み込みを開始するような処理が必要。（turbolinksはrails全体の動作を速めてくれるGem。rails5以降はデフォルトで入っているらしい。）
$(document).on('turbolinks:load', function() { 
    
//■ajaxによるOnesignalIDの取得。
$(window).on('load',function(){
    OneSignal.push(function() {
        OneSignal.getUserId(function(userId) {
        $.ajax({
            url: "users/onesignal_set",
            type: "GET",
            data: {onesignal_id: userId,
            },
            dataType: "html",
            success: function(data) {
            console.log("success")
            },
            error: function(data) {
            console.log("error")
            },
            });   
        });
    }); 
});

//■もっと見るボタン
let $videoblockcount_array =[];
let returnHeight;
//jqueryのeachは指定した要素のすべてに○○を行うという指示ができる。
$(".grad_item").each(function(){ //view側で、動画が4つ以上ある場合grad_item要素ができるような構文にしている。
    let $in_videoblockcount = $(this).children(".video_oneblock").length;
    $videoblockcount_array.push($in_videoblockcount);
    $(this).children(".video_oneblock").slice(4).hide();
});

let playarea
$(".grad_trigger").click(function(){ //トリガーをクリックしたら
    let $triggernum = $('.grad_trigger').index(this); //トリガーが何個目か
    if($(this).hasClass("is_hide")) {
        $(this).addClass("is_show").removeClass("is_hide"); 
        $(this).text("▲閉じる");
        $(".hide_shadow").eq($triggernum).hide();
        $(this).parents(".searchresult_wrapper").find(".video_oneblock").slideDown();
    }else{
        let $scroll_videooneblock_top = $(this).parents(".searchresult_wrapper").find(".video_oneblock").offset().top;
        $(this).removeClass("is_show").addClass("is_hide"); //高さを制限する
        $(this).text("▼すべて開く");
        $(".hide_shadow").eq($triggernum).fadeIn();
        $(this).parents(".searchresult_wrapper").find(".video_oneblock").slice(4).slideUp();
        $('html,body').animate({scrollTop:$scroll_videooneblock_top});
  }
});

});
