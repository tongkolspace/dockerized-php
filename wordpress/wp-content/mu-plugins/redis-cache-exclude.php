<?php 

/**
 * Plugin Name: Exclude cache
 * Plugin URI:  https://tongkolspace.com
 * Description: Custom slug input to exclude cache
 * Version:     1.0.0
 * Author:      Tongkolspace
 * Author URI:  https://Tongkolspace.com/
 * License:     GPL-2.0+
 * License URI: http://www.gnu.org/licenses/gpl-2.0.txt
 * Text Domain: exclude_cache
 * Domain Path: /languages
 * Create by : Fabianus Yayan
 * @package Exclude cache
 */


if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

/**
 * Current plugin version.
 */
define( 'EXCLUDE_CACHE_VERSION', '1.0.0' );

/**
 * Plugin directory and url
 */
define( 'EXCLUDE_CACHE_DIR', plugin_dir_path( __FILE__ ) );
define( 'EXCLUDE_CACHE_URL', plugin_dir_url( __FILE__ ) );


/**
 * kelas exclude cache
 */
class Exclude_cache
{
    /**
     * construct
     */
    function __construct()
    {
        add_action( 'admin_menu', array($this, 'exclude_cache_menu'), 100 );
        add_action('admin_enqueue_scripts',array($this, 'codemirror_enqueue_scripts') );
        add_action( 'send_headers', array( $this, 'check_no_cache_url' ) );
        add_action('admin_footer', array($this,'ec_custom_css'));
    }

    /**
     * exclude cache callback
     */

    public function check_no_cache_url(){

        if(is_admin())
            return;

        $white_list = get_option( 'exclude_cache_custom' );

        global $wp;

        $status = false;

        if(empty($white_list)){
            return;
        }

        $white_list_url = [];
        $white_list_param = [];
        $white_list_regex = [];

        if ( $white_list ) {
            $white_list = str_replace( "\r", '', $white_list );
            $white_list = explode( "\n", $white_list );

            foreach ( $white_list as $key => $value ) {
                if ( '' !== $value ) {
                    if ( wp_http_validate_url( $value ) ) {
                        // if (filter_var( $value , FILTER_VALIDATE_URL)) {
                        $white_list_url[] = trailingslashit( $value ); // URL.
                    } elseif ( $param = parse_url( $value, PHP_URL_QUERY ) ) {
                        $white_list_param[] = $param;  // param. hanya nama param, contoh ?param .
                    } else {
                        $white_list_regex[] = $value; // regex. contoh : /hello-world/i .
                    }
                }
            }
        }

        if ( in_array( trailingslashit( home_url( $wp->request ) ), $white_list_url, true ) ) {
            $status = true;
        }

        if ( in_array(  $wp->request  , $white_list_regex ) ) {
            $status = true;
        }

        $current_url = str_replace( site_url() . '/', '', $this->ec_get_current_url() );


        if ( ! $status ) {
            $parse_url = parse_url( $current_url );

            if ( isset( $parse_url['query'] ) ) {
                $get_query = array();

                $parse_query = parse_str( $parse_url['query'], $get_query );

                if ( is_array( $white_list_param ) ) {

                    foreach ( $white_list_param as $param ) {

                        $pecah = explode( '=', $param );

                        foreach ( $get_query as $query_key => $query ) {
                            if ( isset( $pecah[1] ) ) {
                                if ( $query_key == $pecah[0] && $query == $pecah[1] ) {
                                    $status = true;
                                    break;
                                }
                            } else {
                                if ( $query_key == $pecah[0] ) {
                                    $status = true;
                                    break;
                                }
                            }
                        }
                    }
                }
            }
        }

        if ( ! $status ) {
            if ( count( $white_list_regex ) ) {
                foreach ( $white_list_regex as $key => $value ) {

                    $regex_all = strpos( $value, '/*' );

                    if ( $regex_all ) {

                        $start_with = str_replace( '/*', '', $value );

                        if ( preg_match( '/^' . $start_with . '/', $current_url ) ) {
                            $status = true;
                        }
                    }
                }
            }
        }

        // if($status){
        //     nocache_headers();
        // }

        $this->setup_header_control($status);
    }

    /**
     * setup header control
     */
    public function setup_header_control($status)
    {

        if($status===true) {
            header("Expires: 0");
            header("Cache-Control: no-cache, must-revalidate, max-age=0");

        }

        return; 
    }

    /**
     * register menu 
     */
    public function exclude_cache_menu(){
        add_options_page( 'Exclude Page Cache', 'Exclude Page Cache', 'manage_options', 'exclude-cache', array($this, 'exclude_cache_callback') );
    }

    /**
     * add code mirror js
     */
    function codemirror_enqueue_scripts($hook) {

        $page = (isset($_GET['page'])) ? $_GET['page'] : '';

        if($page!='exclude-cache')
            return;

        $cm_settings['codeEditor'] = wp_enqueue_code_editor(array('type' => 'text/css'));
        wp_localize_script('jquery', 'cm_settings', $cm_settings);

        wp_enqueue_script('wp-theme-plugin-editor');
        wp_enqueue_style('wp-codemirror');
    }

    /**
     * exclude cachec callback
     */
    public function exclude_cache_callback()
    {
?>
        <div class="wrap exclude-cache">
            <h1 class="wp-heading-inline"><?php _e('URL to Exclude Page Cache', 'tongkolspace'); ?></h1>

            <hr class="wp-header-end">
            <?php
            if (isset($_POST['submit'])) {

                if (!isset($_POST['exclude-cache']) || !wp_verify_nonce($_POST['secure'], 'exclude-cache')) {

                    echo "<h2> Wrong connection </h2>";
                    return;
                }

                $data_url = $_POST['exclude-cache'];

                update_option('exclude_cache_custom', $data_url, 'no');
            }
            ?>
            <div class="wrapper-content">
                <h2><?php echo __('Masukkan Url Page Untuk Exclude Cache','tongkolspace'); ?></h2>
                <hr>
                <form method="post" action="">
                    <?php wp_nonce_field('exclude-cache', 'secure'); ?>
                    <?php $get_urls = get_option('exclude_cache_custom'); ?>
                    <table class="form-table">
                        <tr valign="top">
                            <td>
                                <textarea id="exclude-cache" name="exclude-cache"><?php echo $get_urls; ?></textarea>
                            </td>
                        </tr>

                    </table>

                    <script type="text/javascript">
                        jQuery(document).ready(function($) {
                            wp.codeEditor.initialize($('#exclude-cache'), cm_settings);
                        })
                    </script>
                    <?php submit_button(); ?>

                </form>
            </div>
        </div>
        <style type="text/css">
            .exclude-cache .wrapper-content {
                width: 50%;
                background: #fff;
                padding: 10px;
                border-radius: 8px;
            }
        </style>
        <?php
    }


    /**
     * Get Current URL
     *
     * @return [string] $url [url]
     */
    public function ec_get_current_url() {
        $protocol = 'http://';
        if ( ! empty( $_SERVER['HTTPS'] ) ) {
            if ( 'on' === $_SERVER['HTTPS'] ) {
                $protocol = 'https://';
            }
        }
        $url  = $protocol . $_SERVER['SERVER_NAME'];// @( $_SERVER["HTTPS"] != 'on' ) ? 'http://'.$_SERVER["SERVER_NAME"] : 'https://'.$_SERVER["SERVER_NAME"];
        $url .= $_SERVER['REQUEST_URI'];

        return $url;
    }

    /**
     * custom css
     */
    public function ec_custom_css(){
        $currentScreen = get_current_screen();
            if( $currentScreen->id == "settings_page_exclude-cache" ){
        ?>
         <style type="text/css">
            .exclude-cache .wrapper-content{
                width: 50%;
                background: #fff;
                padding: 10px;
                border-radius: 8px;
            }

        </style>
        <?php
            }
    }

}

new Exclude_cache();