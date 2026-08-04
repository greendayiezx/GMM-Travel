import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/website_loader.dart';
import '../../../booking/data/payment_method_remote_data_source.dart';
import '../../../payment_cards/data/saved_card_remote_data_source.dart';
import '../../../payment_cards/presentation/add_saved_card_sheet.dart';

const String _kLogoBniSvg = '''<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 80 24"><g fill-rule="evenodd" clip-rule="evenodd"><path fill="#F15A23" d="m0 8.135 6.749 8.514L0 22.24zm2.716 14.106 5.079-4.248 3.51 4.248zM0 3.58l1.761 2.228 7.242 9.048 2.346-1.868s-1.948-2.294-3.256-4.853C5.536 3.132 7.346.016 7.346.016H0zm10.035 12.673 2.39-1.974s2.282 3.005 4.929 3.714c3.468.93 5.003-1.344 5.003-1.344v5.592H14.74l1.717-1.485s-.896.598-3.088-.92c-1.293-.896-3.334-3.583-3.334-3.583M10.255 0s-.763 1.039-.22 3.58c.58 2.716 2.887 5.59 2.882 5.526 0 0 .148-2.854 1.823-4.53 3.57-3.57 7.617-1.444 7.617-1.444V.016z"/><path fill="#F15A23" d="M22.357 6.896S20.1 4.96 18.137 4.96c-2.512 0-3.883 2.168-3.883 3.741 0 2.29 1.1 3.564 2.204 4.667 1.585 1.586 3.515 3.297 5.9 1.92z"/><path fill="#005E6A" d="M48.072.233H53.4s4.72 7.147 7.04 10.1a341 341 0 0 1 4.816 6.316V1.834c0-.64-1.68-1.601-1.68-1.601h6.145s-2.017.828-2.017 1.6v21.553s-1.934-1.072-4.128-3.621C61.111 16.9 52.344 5.338 52.344 5.338v14.976c0 .767 1.68 1.927 1.68 1.927h-5.952s1.632-1.17 1.632-1.927V1.834c0-.68-1.632-1.601-1.632-1.601m25.09 0H80s-1.836.87-1.836 1.6v18.481c0 .799 1.836 1.927 1.836 1.927h-6.838s1.71-1.154 1.71-1.927V1.834c0-.703-1.71-1.601-1.71-1.601m-45.209 0s1.773.884 1.773 1.6v18.481c0 .786-1.773 1.927-1.773 1.927h10.13c.634 0 7.725-1.16 7.725-6.627S40.3 9.635 40.3 9.635s3.356-.933 3.356-4.674c0-4.032-4.94-4.728-5.572-4.728zm5.382 9.04v-6.88h4.115c.633 0 2.85.739 2.85 3.481 0 2.261-2.216 3.399-2.85 3.399zm0 1.804h4.749c.633 0 4.368.97 4.368 4.212 0 3.304-3.735 4.476-4.368 4.476h-4.75z"/></g></svg>''';

const String _kLogoBriSvg = '''<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 80 41"><path fill="#0857C3" d="M74.954 34.984v4.13h.666v-4.13zm-42.015 0 1.58 4.153-.12.343a1.2 1.2 0 0 1-.23.437.5.5 0 0 1-.301.165.9.9 0 0 1-.372-.029l-.068-.018-.171.577a.8.8 0 0 0 .181.052q.13.026.308.026.291 0 .524-.1a1.1 1.1 0 0 0 .408-.314q.178-.214.3-.543l1.817-4.75h-.724l-.89 2.45q-.13.376-.233.761l-.082.307-.08-.307a9 9 0 0 0-.238-.761l-.879-2.45zm39.49-.051q-.438 0-.786.152-.346.152-.545.427-.2.27-.2.625.001.436.274.716.272.277.836.41l.685.164q.307.07.457.212.151.143.151.357.002.257-.26.438-.254.186-.685.185c-.245 0-.456-.053-.617-.159a.8.8 0 0 1-.334-.499l-.63.155q.071.354.286.596.216.243.544.37.333.122.755.121.488 0 .854-.161.368-.163.572-.446.206-.28.204-.645a1 1 0 0 0-.266-.706q-.274-.277-.833-.409l-.625-.148q-.36-.087-.528-.223a.46.46 0 0 1-.168-.37q0-.258.246-.428.248-.17.617-.17.398.002.596.182.199.18.283.403l.602-.157a1.5 1.5 0 0 0-.279-.514 1.26 1.26 0 0 0-.484-.35 1.8 1.8 0 0 0-.722-.128m-4.225 0q-.562 0-.979.272-.42.273-.65.757a2.6 2.6 0 0 0-.23 1.12q.001.637.235 1.112c.157.32.381.565.668.745q.434.265 1.034.264.426 0 .761-.132c.229-.09.415-.21.57-.37.15-.153.26-.34.323-.546l-.641-.178q-.08.21-.221.356a1 1 0 0 1-.347.21 1.3 1.3 0 0 1-.441.072 1.3 1.3 0 0 1-.662-.167q-.289-.164-.446-.483a1.7 1.7 0 0 1-.157-.689h2.983v-.278q0-.574-.154-.97a1.7 1.7 0 0 0-.417-.635 1.6 1.6 0 0 0-.58-.351 2 2 0 0 0-.65-.11m0 .592q.373-.002.627.179.25.178.377.493.094.234.117.515h-2.303q.016-.282.137-.528a1.2 1.2 0 0 1 .407-.478q.264-.182.638-.181m-4.226-.592q-.466 0-.817.241-.272.184-.445.573l-.005-.763h-.64v4.132h.667V36.64c0-.237.046-.435.136-.603a.94.94 0 0 1 .374-.375q.236-.131.532-.132.433 0 .683.272.249.271.25.745v2.57h.664V36.49q-.001-.522-.176-.868a1.2 1.2 0 0 0-.489-.518 1.5 1.5 0 0 0-.734-.171m-4.76 0q-.563-.002-.988.265-.42.266-.657.75-.239.482-.238 1.126 0 .638.237 1.118.239.478.658.747.425.265.989.264.56 0 .99-.264.425-.269.66-.747.236-.48.237-1.118 0-.645-.237-1.126a1.77 1.77 0 0 0-.66-.75 1.83 1.83 0 0 0-.99-.265m0 .594q.416 0 .686.216.268.214.4.568c.087.239.128.49.128.763q.001.408-.128.755-.132.352-.4.565-.27.215-.685.215-.417-.001-.683-.215a1.3 1.3 0 0 1-.396-.565 2.2 2.2 0 0 1-.128-.755q0-.412.128-.763a1.3 1.3 0 0 1 .396-.568q.266-.216.683-.216m-8.881-.594q-.47 0-.822.241-.27.184-.443.572l-.002-.762h-.641v4.133h.664v-2.478q.001-.354.137-.603a.93.93 0 0 1 .372-.375q.238-.131.534-.132.43 0 .681.272.251.271.252.745v2.57h.664V36.49q0-.522-.177-.868a1.16 1.16 0 0 0-.487-.518 1.5 1.5 0 0 0-.732-.171m-39.1 0q-.467 0-.818.241-.271.184-.445.577l-.003-.767h-.64v4.132h.667V36.64c0-.237.043-.435.136-.603a.94.94 0 0 1 .373-.375q.237-.131.532-.132.434 0 .683.272.249.271.25.745v2.57h.662V36.49q0-.522-.173-.868a1.17 1.17 0 0 0-.49-.518 1.5 1.5 0 0 0-.733-.171m67.084-.002c-.215 0-.427.03-.644.088a1.8 1.8 0 0 0-.594.302 1.44 1.44 0 0 0-.431.592l.64.208q.067-.143.198-.283a1 1 0 0 1 .342-.229q.21-.094.507-.092.285-.001.48.094a.66.66 0 0 1 .29.279.9.9 0 0 1 .095.435v.023c0 .101-.041.171-.113.215a.9.9 0 0 1-.347.086l-.603.074c-.19.027-.384.058-.57.101a1.9 1.9 0 0 0-.521.192.96.96 0 0 0-.373.349c-.095.149-.143.338-.143.576q-.001.406.19.69c.124.19.3.339.505.432q.322.149.714.148.35 0 .6-.103a1.3 1.3 0 0 0 .4-.255q.155-.155.226-.3h.045v.563h.654v-2.723q.002-.485-.16-.776a1.13 1.13 0 0 0-.407-.435 1.5 1.5 0 0 0-.51-.198 2.5 2.5 0 0 0-.47-.053m.883 2.12v.574a.96.96 0 0 1-.132.478 1 1 0 0 1-.39.376 1.23 1.23 0 0 1-.625.147 1.2 1.2 0 0 1-.437-.075.7.7 0 0 1-.306-.218.6.6 0 0 1-.11-.361q-.001-.233.126-.374a.8.8 0 0 1 .333-.208 2.3 2.3 0 0 1 .45-.103q.096-.01.257-.033a6 6 0 0 0 .343-.05 a3 3 0 0 0 .313-.068q.135-.038.178-.085m-40.13-2.12c-.212 0-.424.03-.645.088a1.8 1.8 0 0 0-.594.302q-.27.212-.427.592l.639.208a1.1 1.1 0 0 1 .198-.283q.13-.14.34-.229a1.2 1.2 0 0 1 .508-.092q.287-.001.481.094a.64.64 0 0 1 .287.279.9.9 0 0 1 .099.435v.023q0 .15-.114.215a1 1 0 0 1-.347.086c-.152.02-.356.043-.602.074a7 7 0 0 0-.573.101q-.284.063-.518.192a.97.97 0 0 0-.373.349 1.05 1.05 0 0 0-.145.576q0 .406.192.69c.124.19.3.34.505.432q.322.149.712.148.353 0 .598-.103c.167-.068.3-.156.405-.255q.154-.155.225-.3h.045v.563h.654v-2.723q-.002-.485-.16-.776a1.13 1.13 0 0 0-.407-.435 1.4 1.4 0 0 0-.51-.198 2.5 2.5 0 0 0-.472-.053m.886 2.12v.574a.96.96 0 0 1-.133.478q-.135.232-.391.376-.255.148-.623.147-.25 0-.438-.075a.7.7 0 0 1-.305-.218.6.6 0 0 1-.11-.361q0-.233.124-.374a.8.8 0 0 1 .335-.208q.208-.073.45-.103l.262-.033q.161-.019.336-.05.158-.023.313-.068a.4.4 0 0 0 .18-.085m-13.505-2.12q-.318 0-.642.088c-.216.063-.42.165-.598.302q-.27.212-.427.592l.64.208a1.04 1.04 0 0 1 .538-.512q.21-.094.507-.092.288-.001.481.094a.65.65 0 0 1 .287.279.9.9 0 0 1 .095.435v.023q0 .15-.112.215a.9.9 0 0 1-.344.086l-.602.074a7 7 0 0 0-.574.101q-.286.063-.52.192a1 1 0 0 0-.376.349c-.093.149-.14.338-.14.576q.001.406.188.69c.126.19.303.338.51.432q.32.149.711.148.352 0 .599-.103c.165-.068.299-.156.404-.255q.154-.155.225-.3h.045v.563h.652v-2.723q0-.485-.16-.776a1.13 1.13 0 0 0-.407-.435 1.5 1.5 0 0 0-.512-.198 2.4 2.4 0 0 0-.468-.053m.88 2.12v.574a.99.99 0 0 1-.52.854 1.2 1.2 0 0 1-.622.147q-.249 0-.442-.075a.7.7 0 0 1-.303-.218.57.57 0 0 1-.112-.361q0-.233.129-.374a.8.8 0 0 1 .332-.208 2.3 2.3 0 0 1 .45-.103q.098-.01.26-.033.165-.02.34-.05.158-.023.311-.068.139-.038.178-.085M6.62 34.931q-.318 0-.643.088a1.8 1.8 0 0 0-.595.302q-.27.212-.427.592l.638.208q.075-.156.196-.283.135-.138.342-.229.211-.094.506-.092.288-.001.48.094c.124.06.227.157.292.279a.9.9 0 0 1 .094.435v.023q0 .15-.111.215a.9.9 0 0 1-.347.086l-.604.074a7 7 0 0 0-.574.101c-.185.042-.36.106-.515.192a1 1 0 0 0-.376.349c-.093.149-.14.338-.14.576q-.002.406.187.69c.126.19.302.339.508.432q.32.149.712.148.35 0 .6-.103c.163-.068.297-.156.4-.255q.159-.155.227-.3h.044v.563h.653v-2.723q-.001-.485-.16-.776a1.1 1.1 0 0 0-.407-.435 1.4 1.4 0 0 0-.51-.198 2.4 2.4 0 0 0-.47-.053m.883 2.12v.574a.96.96 0 0 1-.132.478q-.134.232-.387.376a1.23 1.23 0 0 1-.628.147q-.246 0-.437-.075a.67.67 0 0 1-.303-.218.57.57 0 0 1-.112-.361q0-.233.126-.374a.76.76 0 0 1 .334-.208 2.3 2.3 0 0 1 .448-.103q.095-.01.262-.033a6 6 0 0 0 .34-.05q.173-.027.312-.068.136-.038.177-.085M41.903 34v.984h-.621v.57h.621v2.54q0 .509.297.79.303.283.838.282.127 0 .258-.018.12-.014.235-.054l-.136-.562-.177.03q-.081.014-.162.016-.264 0-.377-.13-.111-.127-.111-.404v-2.49h.85v-.57h-.85V34zm13.8-.39v2.036h-.053a3 3 0 0 0-.192-.28 1.2 1.2 0 0 0-.367-.301q-.236-.131-.638-.132-.514-.002-.91.26a1.7 1.7 0 0 0-.619.736q-.224.48-.223 1.133 0 .654.221 1.139c.149.317.355.567.62.74a1.6 1.6 0 0 0 .907.262q.395.001.633-.134.239-.133.37-.307.133-.171.198-.285h.074v.64h.644V33.61zm-1.153 1.917q.379 0 .638.194.26.19.392.532.128.341.127.8c0 .308-.04.576-.132.811a1.2 1.2 0 0 1-.39.547 1.02 1.02 0 0 1-.635.198 1 1 0 0 1-.648-.209 1.25 1.25 0 0 1-.394-.563 2.3 2.3 0 0 1-.132-.784q.001-.428.13-.773.13-.349.39-.55.262-.203.654-.203m-8.073-1.917v5.506h.701V33.61zm-17.305 0v5.506h.664V37.59l.435-.408 1.513 1.934h.852l-1.857-2.356 1.727-1.776h-.823l-1.766 1.822h-.08V33.61zm-9.005 0v5.506h.7V36.98h1.19q.064 0 .127-.003l1.145 2.14h.815l-1.235-2.263q.108-.038.203-.087.415-.21.618-.59.2-.375.2-.868 0-.492-.2-.875a1.43 1.43 0 0 0-.62-.604c-.276-.149-.627-.219-1.058-.219zm.7.615h1.148q.439 0 .708.134c.173.09.305.217.386.378q.123.243.123.571 0 .325-.123.557a.8.8 0 0 1-.386.36q-.262.13-.7.131h-1.155zm-7.063-.615v5.506h.666V37.59l.435-.408 1.51 1.934h.855l-1.857-2.356 1.727-1.776h-.823l-1.768 1.822h-.079V33.61zm-13.594 0v5.506h2.016q.65 0 1.056-.195.405-.19.597-.527c.13-.22.19-.47.19-.746q0-.43-.172-.733a1.3 1.3 0 0 0-.427-.462 1.1 1.1 0 0 0-.515-.175v-.052q.237-.066.443-.202.207-.14.33-.37.127-.23.126-.588 0-.4-.182-.73a1.3 1.3 0 0 0-.557-.528c-.252-.132-.567-.198-.953-.198zm.702.621H2.15q.532-.002.784.248a.82.82 0 0 1 .247.604q.001.285-.14.5a.95.95 0 0 1-.38.327 1.2 1.2 0 0 1-.536.116H.912zm0 2.387h1.333q.352 0 .612.14.251.143.396.372a.97.97 0 0 1 .139.511.79.79 0 0 1-.27.607c-.18.163-.488.247-.915.247H.912zm74.378-3.19a.46.46 0 0 0-.326.126.4.4 0 0 0-.136.314q-.002.18.136.31.135.13.326.13a.45.45 0 0 0 .326-.13.4.4 0 0 0 .138-.31.41.41 0 0 0-.138-.314.46.46 0 0 0-.326-.126m.937-30.787a.37.37 0 0 0-.371.372v23.838a.37.37 0 0 0 .37.374h3.405a.26.26 0 0 0 .12-.027.36.36 0 0 0 .249-.347V3.013a.37.37 0 0 0-.37-.372zm-20.416 0a.373.373 0 0 0-.372.372v23.838c0 .207.167.374.372.374h3.309a.373.373 0 0 0 .373-.374V18.19a.367.367 0 0 1 .37-.37h2.675a.37.37 0 0 1 .3.155l6.39 9.092a.38.38 0 0 0 .304.159h3.809a.37.37 0 0 0 .3-.586l-6.015-8.562a.373.373 0 0 1 .212-.573c.966-.254 1.822-.632 2.542-1.123a7.5 7.5 0 0 0 1.81-1.724 6.8 6.8 0 0 0 1.064-2.16c.23-.796.347-1.62.348-2.447a8.2 8.2 0 0 0-.536-2.996 6.26 6.26 0 0 0-1.586-2.32c-.708-.65-1.61-1.168-2.676-1.536-1.081-.369-2.348-.557-3.77-.557zm4.051 3.6h5.21c.305 0 .6.019.903.056.935.143 1.704.48 2.292 1.011.811.732 1.224 1.643 1.224 2.707a4.7 4.7 0 0 1-.256 1.527 3.56 3.56 0 0 1-.821 1.343c-.371.383-.852.697-1.424.932-.571.235-1.26.355-2.05.355h-5.078a.37.37 0 0 1-.369-.374V6.611a.367.367 0 0 1 .37-.37m-23.395-3.6a.37.37 0 0 0-.371.372v23.838c0 .207.167.374.37.374h9.39c1.42 0 2.672-.196 3.726-.576 1.042-.38 1.917-.905 2.597-1.564a6.2 6.2 0 0 0 1.523-2.308c.332-.879.501-1.84.501-2.851 0-1.35-.311-2.565-.926-3.613-.621-1.056-1.35-1.879-2.172-2.45a.372.372 0 0 1-.05-.568c.16-.16.357-.373.578-.631a5.2 5.2 0 0 0 .61-.883 6 6 0 0 0 .494-1.141 4.3 4.3 0 0 0 .197-1.314c0-.937-.16-1.822-.478-2.633a5.6 5.6 0 0 0-1.46-2.104c-.661-.603-1.498-1.083-2.495-1.426-1.005-.344-2.2-.522-3.55-.522zm3.961 3.6h4.38c.852 0 1.578.108 2.16.322h.001c.39.15.72.349.972.592.65.623.98 1.379.98 2.25 0 .753-.134 1.392-.402 1.901-.256.487-.522.869-.786 1.135l-.11.11h-7.195a.37.37 0 0 1-.372-.374l.001-5.566a.37.37 0 0 1 .371-.37m0 9.949h5.678c1.38 0 2.422.371 3.109 1.108a3.74 3.74 0 0 1 .97 2.554c0 1.01-.374 1.887-1.102 2.605-.733.716-1.917 1.081-3.524 1.081h-5.13a.37.37 0 0 1-.372-.371V16.56a.37.37 0 0 1 .371-.371M4.408 0A4.407 4.407 0 0 0 0 4.41v21.15a4.41 4.41 0 0 0 4.409 4.412h21.15a4.41 4.41 0 0 0 4.413-4.413V4.411A4.41 4.41 0 0 0 25.56 0zm0 3.438h2.868v.015a3.48 3.48 0 0 1 2.406.868c.053.048.107.101.157.15 1.35 1.348 1.33 3.384-.037 4.964l-4.516 4.962a.87.87 0 0 0 0 1.172l4.485 4.927.043.051c1.38 1.504 1.393 3.584.025 4.947a3.45 3.45 0 0 1-2.562 1.021v.016H4.408a.97.97 0 0 1-.972-.972V4.409a.97.97 0 0 1 .972-.971m8.95 0h3.17v.016a3.5 3.5 0 0 1 2.407.868c.054.048.107.101.157.15 1.349 1.348 1.33 3.384-.037 4.965l-4.465 5.01a.876.876 0 0 0 .012 1.177L24.801 26.53H13.358c1.537-2.597 1.19-5.937-1.041-8.345l-2.914-3.2 2.88-3.17.062-.063c2.197-2.484 2.53-5.754 1.013-8.314m9.251.001h2.95a.97.97 0 0 1 .972.972v18.881l-7.825-8.363 2.828-3.111.06-.065C23.791 9.27 24.128 6 22.61 3.44"/></svg>''';

const String _kLogoMandiriSvg = '''<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 80 25"><g fill-rule="evenodd" clip-rule="evenodd"><path fill="url(#paint0_linear_3802_8197)" d="M58.899.896c-1.54.921-5.172 3.073-6.529 3.875-.826.435-2.74.624-3.822-.883-.02-.028-1.44-1.86-1.498-1.93-.041-.049-.96-1.456-3.005-1.5-.303-.007-1.806-.015-3.273.846L34.29 5.13q0 .002-.004.003l-3.316 1.96 1.715 2.176c.803 1.03 2.613 1.826 4.182.895 0 0 5.8-3.469 5.821-3.479 2.508-1.42 4.444-1.42 5.728-.892 1.153.503 2.156 1.757 2.156 1.757s1.31 1.678 1.542 1.972c.746.948 1.98.576 1.98.576s.458-.054 1.148-.477l5.62-3.365c1.784-1.081 3.42-1.283 4.256-1.204 2.62.246 3.433 2.136 4.568 3.454.669.776 1.272 1.216 2.195 1.194.606-.013 1.291-.393 1.392-.462L80 5.228s-.69-1.073-2.104-2.744c-1.265-1.49-2.609-.816-3.68-.268-.45.23-2.08 1.35-3.697 2.132-1.15.557-2.805.39-3.71-.767-.055-.07-1.521-1.904-1.675-2.13C64.542.686 63.387 0 61.907 0c-.9 0-1.92.253-3.008.896"/><path fill="#003A70" d="M.084 16.573A45 45 0 0 0 0 13.475h2.194l.103 1.54h.062c.497-.814 1.406-1.776 3.103-1.776 1.324 0 2.358.771 2.792 1.925h.043c.352-.577.764-1.004 1.24-1.304.559-.406 1.2-.62 2.028-.62 1.675 0 3.37 1.174 3.37 4.508v6.132h-2.482v-5.746c0-1.731-.578-2.758-1.798-2.758-.87 0-1.512.642-1.78 1.39a3.8 3.8 0 0 0-.124.874v6.24H6.268v-6.025c0-1.452-.558-2.479-1.737-2.479-.952 0-1.592.77-1.82 1.495a2.3 2.3 0 0 0-.146.855v6.154H.085zm24.521 4.807c0 .94.041 1.858.145 2.5h-2.297l-.165-1.153h-.062c-.62.813-1.676 1.389-2.979 1.389-2.027 0-3.165-1.516-3.165-3.098 0-2.63 2.254-3.953 5.978-3.931v-.172c0-.684-.27-1.816-2.048-1.816-.993 0-2.028.321-2.71.769l-.497-1.708c.746-.47 2.05-.92 3.642-.92 3.228 0 4.158 2.116 4.158 4.38zm-2.483-2.584c-1.8-.043-3.516.363-3.516 1.944 0 1.025.641 1.496 1.448 1.496a2.07 2.07 0 0 0 1.985-1.432c.062-.192.083-.407.083-.577zm4.242-2.223a47 47 0 0 0-.083-3.098h2.232l.125 1.56h.061c.435-.81 1.531-1.796 3.207-1.796 1.758 0 3.579 1.175 3.579 4.467v6.174H32.94v-5.875c0-1.496-.538-2.629-1.924-2.629-1.014 0-1.717.748-1.986 1.539-.082.236-.103.557-.103.854v6.111h-2.564zm20.152-7.278v11.657c0 1.068.04 2.224.082 2.929h-2.276l-.102-1.645h-.042c-.6 1.154-1.822 1.88-3.29 1.88-2.398 0-4.301-2.115-4.301-5.32-.022-3.483 2.088-5.556 4.508-5.556 1.386 0 2.38.599 2.834 1.369h.042V9.295zM43.97 17.81c0-.211-.021-.469-.061-.682-.228-1.025-1.035-1.859-2.194-1.859-1.634 0-2.544 1.496-2.544 3.44 0 1.902.91 3.29 2.524 3.29 1.033 0 1.944-.725 2.192-1.857a3 3 0 0 0 .083-.771zm4.343 6.07h2.568V13.476h-2.568zm4.366-7.05c0-1.41-.022-2.416-.083-3.355h2.214l.08 1.986h.086c.496-1.474 1.675-1.986 2.75-1.986.248 0 .393-.044.6 0v2.308a3.4 3.4 0 0 0-.745-.085c-1.22 0-2.048.811-2.275 1.985-.04.236-.082.515-.082.815v5.383h-2.545zm6.826 7.05h2.564V13.476h-2.564z"/></g><defs><linearGradient id="paint0_linear_3802_8197" x1="0" x2="80" y1="24.116" y2="24.116" gradientUnits="userSpaceOnUse"><stop stop-color="#FFCA06"/><stop offset=".331" stop-color="#FBAA18"/><stop offset=".695" stop-color="#FFC907"/><stop offset="1" stop-color="#FAA619"/></linearGradient></defs></svg>''';

const String _kLogoBcaSvg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 40" fill="none"><path d="M10 8h8v24H10z" fill="#003D79"/><path d="M22 8h4c6 0 10 3 10 8s-4 8-10 8h-4V8z" fill="#003D79"/><text x="48" y="28" font-family="Arial Black, Arial" font-weight="900" font-size="24" fill="#003D79">BCA</text></svg>''';

const String _kLogoDanaSvg = '''<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 80 23"><g><path fill="#008CEB" fill-rule="evenodd" d="M31.623 17.349c1.52.109 3.292-1.073 3.916-1.747 2.17-2.348 2.222-5.742.038-8.201-.813-.915-2.722-1.927-3.93-1.784H27.27v11.717l4.363.015zm-1.885-2.539V8.14a16 16 0 0 1 2.057 0 3.2 3.2 0 0 1 1.493.578c2.513 1.718 1.466 5.812-1.535 6.086q-1.007.071-2.015.006m40.292 2.56h2.494v-2.526h4.948l.015 2.513h2.494v-4.163c0-1.257.105-2.823-.21-3.96a4.947 4.947 0 0 0-9.526-.053c-.335 1.123-.222 2.733-.222 3.98 0 1.407-.015 2.822 0 4.23zm2.496-5.066c-.015-1.047-.126-2.168.366-2.974a2.43 2.43 0 0 1 2.126-1.209 2.47 2.47 0 0 1 2.11 1.22c.487.837.371 1.884.359 2.965zm-31.02 5.064h2.486c0-.528-.067-2.143.023-2.526h4.93l.016 2.523h2.49c-.012-1.398 0-2.795 0-4.188 0-1.194.111-2.903-.21-3.962a4.948 4.948 0 0 0-9.526-.049c-.333 1.09-.22 2.754-.22 3.967 0 1.399-.031 2.834 0 4.228zm2.488-5.064c-.017-1.047-.124-2.183.368-2.972a2.453 2.453 0 0 1 4.237 0c.488.838.37 1.901.362 2.967zm11.832-2.111-.035 1.744c0 1.466-.072 4.203 0 5.395h2.437c.057-.838-.088-6.788.065-6.978 0-1.156 1.209-2.233 2.427-2.237a2.43 2.43 0 0 1 1.7.679c.31.283.786.928.778 1.579.113.065.023 6.283.059 6.972h2.44l-.02-7.11c.061-.557-.274-1.418-.49-1.854a4.934 4.934 0 0 0-8.852-.075c-.21.43-.561 1.313-.509 1.885" clip-rule="evenodd"/><path fill="#008CEB" d="M11.437 22.873c6.316 0 11.436-5.12 11.436-11.436C22.873 5.12 17.753 0 11.437 0 5.12 0 0 5.12 0 11.437s5.12 11.436 11.437 11.436"/><path fill="#FEFEFE" d="M18.1 11.485v3.219c0 .21-.09.253-.265.15a6 6 0 0 0-.733-.372 5 5 0 0 0-2.407-.32c-.89.115-1.765.334-2.605.653-.838.282-1.659.588-2.513.825a7 7 0 0 1-2.182.287 4.63 4.63 0 0 1-2.304-.719.57.57 0 0 1-.274-.506V8.377c0-.103 0-.224.092-.276s.186.033.266.085a4.4 4.4 0 0 0 2.544.754 6.8 6.8 0 0 0 1.902-.354c.871-.27 1.713-.628 2.57-.932q1-.385 2.046-.628a4.44 4.44 0 0 1 3.503.647.77.77 0 0 1 .367.685V11.5z"/></g></svg>''';

const String _kLogoGopaySvg = '''<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 80 18"><g><path fill="#00AED6" d="M8.732 17.463A8.732 8.732 0 1 0 8.732 0a8.732 8.732 0 0 0 0 17.463"/><path fill="#00AED6" d="M8.732 17.463A8.732 8.732 0 1 0 8.732 0a8.732 8.732 0 0 0 0 17.463"/><path fill="#fff" fill-rule="evenodd" d="M13.817 8.46A2.03 2.03 0 0 0 11.7 6.55H6.185a.364.364 0 0 1 0-.728h5.588a1.74 1.74 0 0 0-1.274-1.604 14.2 14.2 0 0 0-4.922 0A2.32 2.32 0 0 0 3.831 6.16a17.3 17.3 0 0 0 0 5.17c.196.998.988 1.77 1.99 1.943 2.02.251 4.065.251 6.086 0a2.13 2.13 0 0 0 1.689-1.834c.18-.982.255-1.981.221-2.98m-1.811 1.222v.324a.364.364 0 0 1-.728 0v-.324a.546.546 0 1 1 .728 0" clip-rule="evenodd"/><path fill="#000" d="M24.366 13.078a3.75 3.75 0 0 0 3.263 1.595c1.52 0 2.639-.972 2.639-2.292v-.696h-.037a4.14 4.14 0 0 1-3.134 1.173 5.079 5.079 0 1 1-.092-10.155 4.36 4.36 0 0 1 3.226 1.136h.037v-.953h2.603v9.459c0 2.75-2.181 4.656-5.242 4.656a6.26 6.26 0 0 1-5.206-2.31zm5.793-5.884c0-1.1-1.247-2.108-2.64-2.108-1.76 0-2.933 1.063-2.933 2.658a2.568 2.568 0 0 0 2.823 2.731c1.522 0 2.75-.953 2.75-2.145zM39.69 2.61c3.172 0 5.482 2.255 5.482 5.133s-2.31 5.132-5.482 5.132a5.143 5.143 0 1 1 0-10.265m0 2.383a2.75 2.75 0 1 0 2.769 2.75 2.63 2.63 0 0 4-2.769-2.75m6.948-2.108h2.604v.862h.037a4.32 4.32 0 0 1 3.133-1.137 5.134 5.134 0 0 1 .019 10.265 4.7 4.7 0 0 1-3.043-1.026h-.037v4.876h-2.713zm5.354 2.126c-1.431 0-2.64 1.009-2.64 2.109v1.228c0 1.173 1.173 2.144 2.657 2.144a2.74 2.74 0 0 0-.017-5.48M62.568 6.81c1.778-.238 2.31-.495 2.31-.99 0-.642-.678-1.026-1.723-1.026a2.29 2.29 0 0 0-2.42 1.74l-2.567-.53c.367-1.98 2.402-3.392 4.913-3.392 2.841 0 4.602 1.449 4.602 3.813V12.6h-2.439v-1.063h-.037a4.01 4.01 0 0 1-3.281 1.338c-2.145 0-3.629-1.173-3.629-2.896 0-1.815 1.21-2.75 4.271-3.171m2.53 1.027h-.037c-.239.348-.752.55-2.07.788-1.597.293-2.164.604-2.164 1.173 0 .587.476.843 1.502.843 1.56 0 2.769-.715 2.769-1.65zm7.496 4.234-4.49-9.184h2.988l2.95 6.342h.037l2.915-6.342H80l-6.726 13.84h-2.99z"/></g></svg>''';

const String _kLogoOvoSvg = '''<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 64 65"><g><path fill="#5827D4" d="M31.957 64.938q-9.288 0-16.532-4.091Q8.18 56.67 4.09 49.342 0 41.928 0 32.554t4.09-16.788q4.176-7.414 11.42-11.59Q22.839 0 32.128 0q9.204 0 16.447 4.176 7.329 4.09 11.334 11.504Q64 23.095 64 32.554q0 9.375-4.09 16.788-4.091 7.329-11.42 11.505-7.244 4.09-16.533 4.09m0-5.029q7.926 0 13.976-3.408 6.051-3.41 9.375-9.63 3.408-6.222 3.408-14.317 0-8.096-3.323-14.317-3.323-6.306-9.374-9.715-6.05-3.495-13.891-3.494-7.84 0-13.976 3.494-6.135 3.408-9.545 9.715-3.323 6.221-3.323 14.317T8.607 46.87t9.374 9.63 13.976 3.409m0-2.386q-7.158 0-12.697-3.068-5.54-3.153-8.608-8.777-2.982-5.71-2.982-13.124t3.068-13.124q3.068-5.709 8.522-8.863 5.539-3.153 12.697-3.153 7.159 0 12.698 3.153t8.607 8.948q3.069 5.71 3.068 13.039t-3.068 13.039q-3.068 5.624-8.607 8.777t-12.698 3.153m0-5.028q5.625 0 9.971-2.471 4.347-2.556 6.733-7.073 2.386-4.602 2.386-10.397 0-5.88-2.472-10.397Q46.19 17.555 41.843 15q-4.347-2.557-9.886-2.557T22.072 15t-6.732 7.158q-2.387 4.517-2.387 10.397 0 5.795 2.387 10.397 2.385 4.516 6.732 7.073 4.346 2.472 9.885 2.471"/></g></svg>''';

const String _kLogoQrisSvg = '''<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 80 30"><g fill="#000"><path d="M76.723 10.477H64.024V7.936h12.699v-5.08H56.405v12.699h12.699v2.541H56.405v5.08h20.318zM53.867 2.856h-5.08v20.317h5.08zm-27.937 0v5.08h15.238v2.541H25.931v12.699h5.077v-7.544l7.621 7.544h7.619l-7.95-7.621h7.95V2.856zM10.69 15.555h5.067v-5.067h-5.066zm1.273-3.808H14.5v2.538h-2.538z"/><path d="M8.152 2.856H3.707a.64.64 0 0 0-.587.393.6.6 0 0 0-.048.244V22.54a.635.635 0 0 0 .635.634H15.77v-5.066H8.152zm14.603 0H10.69v5.08h7.621v7.619h5.067V3.493a.64.64 0 0 0-.179-.45.65.65 0 0 0-.445-.187m.638 15.24h-5.08v11.43h5.08z"/><path d="M10.16 0H.635A.637.637 0 0 0 0 .635v9.525h1.27V1.893a.637.637 0 0 1 .634-.624h8.267zm68.57 16.507v8.266a.637.637 0 0 1-.634.635h-8.267v1.259h9.526a.64.64 0 0 0 .645-.635v-9.525z"/></g></svg>''';

String? _svgForCode(String code) {
  final c = code.toUpperCase();
  if (c.contains('BNI')) return _kLogoBniSvg;
  if (c.contains('BRI')) return _kLogoBriSvg;
  if (c.contains('MANDIRI')) return _kLogoMandiriSvg;
  if (c.contains('BCA')) return _kLogoBcaSvg;
  if (c.contains('DANA')) return _kLogoDanaSvg;
  if (c.contains('GOPAY')) return _kLogoGopaySvg;
  if (c.contains('OVO')) return _kLogoOvoSvg;
  if (c.contains('QRIS')) return _kLogoQrisSvg;
  return null;
}

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  final PaymentMethodRemoteDataSource _dataSource =
      PaymentMethodRemoteDataSource();
  final SavedCardRemoteDataSource _cardsDataSource = SavedCardRemoteDataSource();

  static const List<PaymentMethod> _defaultMethods = [
    PaymentMethod(id: '1', name: 'BNI Virtual Account', code: 'BNI_VA', gateway: 'MIDTRANS'),
    PaymentMethod(id: '2', name: 'BRI Virtual Account', code: 'BRI_VA', gateway: 'MIDTRANS'),
    PaymentMethod(id: '3', name: 'Mandiri Virtual Account', code: 'MANDIRI_VA', gateway: 'MIDTRANS'),
    PaymentMethod(id: '4', name: 'BCA Virtual Account', code: 'BCA_VA', gateway: 'MIDTRANS'),
    PaymentMethod(id: '5', name: 'DANA', code: 'DANA', gateway: 'MIDTRANS'),
    PaymentMethod(id: '6', name: 'GoPay', code: 'GOPAY', gateway: 'MIDTRANS'),
    PaymentMethod(id: '7', name: 'OVO', code: 'OVO', gateway: 'MIDTRANS'),
    PaymentMethod(id: '8', name: 'QRIS', code: 'QRIS', gateway: 'MIDTRANS'),
  ];

  List<PaymentMethod>? _methods;
  bool _isLoading = true;
  Object? _error;

  List<SavedCard> _savedCards = [];
  bool _isLoadingCards = true;

  @override
  void initState() {
    super.initState();
    _loadMethods();
    _loadSavedCards();
  }

  Future<void> _loadMethods() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await _dataSource.fetchPaymentMethods();
      if (mounted) {
        setState(() => _methods = list.isNotEmpty ? list : _defaultMethods);
      }
    } catch (_) {
      if (mounted) setState(() => _methods = _defaultMethods);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSavedCards() async {
    setState(() => _isLoadingCards = true);
    try {
      final list = await _cardsDataSource.fetchSavedCards();
      if (mounted) setState(() => _savedCards = list);
    } catch (_) {
      // Backend offline/gagal → tampilkan empty state, bukan kartu dummy.
      if (mounted) setState(() => _savedCards = []);
    } finally {
      if (mounted) setState(() => _isLoadingCards = false);
    }
  }

  Future<void> _confirmDeleteCard(SavedCard card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kartu'),
        content: Text('Hapus kartu ${card.maskedCard}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _cardsDataSource.deleteSavedCard(card.id);
      if (!mounted) return;
      setState(() => _savedCards.removeWhere((c) => c.id == card.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kartu berhasil dihapus.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus kartu.')),
      );
    }
  }

  String _formatMaskedCard(String maskedCard) {
    final digits = maskedCard.replaceAll(RegExp(r'[^0-9]'), '');
    final last4 = digits.length >= 4 ? digits.substring(digits.length - 4) : digits;
    return '**** **** **** $last4';
  }

  List<PaymentMethod> get _virtualAccounts =>
      (_methods ?? []).where((m) => m.code.endsWith('_VA')).toList();

  List<PaymentMethod> get _eWallets =>
      (_methods ?? []).where((m) => m.isEwallet).toList();

  List<PaymentMethod> get _others => (_methods ?? [])
      .where((m) => !m.code.endsWith('_VA') && !m.isEwallet)
      .toList();

  @override
  Widget build(BuildContext context) {
    final hPadding = Responsive.horizontalPadding(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.azureSky),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Metode Pembayaran',
          style: TextStyle(
            fontFamily: 'Avenir',
            fontSize: Responsive.fontSize(context, 18),
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1C1B1B),
          ),
        ),
      ),
      body: _isLoading
          ? _buildLoadingSkeleton()
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_off_rounded,
                        size: 48,
                        color: AppColors.outlineVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Gagal memuat metode pembayaran',
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 14),
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadMethods,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.azureSky,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: hPadding, vertical: 20,
                  ),
                  child: Responsive.constrainWidth(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      // ── Kartu Tersimpan Section ─────────────────────
                      _buildSavedCardsSection(context),

                      if (_virtualAccounts.isNotEmpty) ...[
                        Text(
                          'Bank Transfer (Virtual Account)',
                          style: TextStyle(
                            fontFamily: 'Avenir',
                            fontSize: Responsive.fontSize(context, 16),
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildMethodsContainer(
                          _virtualAccounts.map((m) => _buildMethodTile(m)).toList(),
                        ),
                        const SizedBox(height: 28),
                      ],
                      if (_eWallets.isNotEmpty) ...[
                        Text(
                          'E-Wallet',
                          style: TextStyle(
                            fontFamily: 'Avenir',
                            fontSize: Responsive.fontSize(context, 16),
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildMethodsContainer(
                          _eWallets.map((m) => _buildMethodTile(m)).toList(),
                        ),
                        const SizedBox(height: 28),
                      ],
                      if (_others.isNotEmpty) ...[
                        Text(
                          'Metode Lainnya',
                          style: TextStyle(
                            fontFamily: 'Avenir',
                            fontSize: Responsive.fontSize(context, 16),
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildMethodsContainer(
                          _others.map((m) => _buildMethodTile(m)).toList(),
                        ),
                      ],
                      if ((_methods ?? []).isEmpty) ...[
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: 48,
                                  color: AppColors.outlineVariant,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Belum ada metode pembayaran tersedia',
                                  style: TextStyle(
                                    fontSize: Responsive.fontSize(context, 14),
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 36),
                      // ── Security Badge Footer ─────────────────────────
                      Center(
                        child: Opacity(
                          opacity: 0.6,
                          child: Column(
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.lock_outline_rounded,
                                    size: 14,
                                    color: AppColors.outline,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'SECURE 256-BIT SSL ENCRYPTION',
                                    style: TextStyle(
                                      fontSize:
                                          Responsive.fontSize(context, 10),
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.outline,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Data pembayaran Anda dijamin aman dan terenkripsi sesuai standar PCI-DSS.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize:
                                      Responsive.fontSize(context, 10),
                                  color: AppColors.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    ),
                  ),
                ),
    );
  }

  void _showMethodSnack(PaymentMethod m) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Menampilkan instruksi pembayaran ${m.name}...')),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ShimmerLoader(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.horizontalPadding(context),
          vertical: 20,
        ),
        child: Responsive.constrainWidth(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  SkeletonBox(width: 150, height: 18),
                  SkeletonBox(width: 40, height: 16),
                ],
              ),
              const SizedBox(height: 12),
              const SkeletonBox(height: 192, width: double.infinity, borderRadius: 20),
              const SizedBox(height: 14),
              const SkeletonBox(height: 192, width: double.infinity, borderRadius: 20),
              const SizedBox(height: 14),
              const SkeletonBox(height: 72, width: double.infinity, borderRadius: 16),
              const SizedBox(height: 28),
              const SkeletonBox(width: 220, height: 18),
              const SizedBox(height: 12),
              for (var i = 0; i < 4; i++) ...[
                const _MethodTileSkeleton(),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 24),
              Center(
                child: Container(
                  alignment: Alignment.center,
                  child: const SkeletonBox(width: 220, height: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _colorForCardIndex(int index) {
    const colors = [Color(0xFF1E9BF0), Color(0xFF1A1A1A), Color(0xFF2E7D32)];
    return colors[index % colors.length];
  }

  // ── Kartu Tersimpan ────────────────────────────────────────────
  Widget _buildSavedCardsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kartu Tersimpan',
          style: TextStyle(
            fontFamily: 'Avenir',
            fontSize: Responsive.fontSize(context, 16),
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoadingCards) ...[
          const SkeletonBox(height: 192, width: double.infinity, borderRadius: 20),
          const SizedBox(height: 14),
        ] else if (_savedCards.isEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.35)),
            ),
            child: Column(
              children: [
                const Icon(Icons.credit_card_off_rounded, size: 40, color: AppColors.outlineVariant),
                const SizedBox(height: 10),
                Text(
                  'Belum ada kartu tersimpan',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 13),
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ] else ...[
          for (var i = 0; i < _savedCards.length; i++) ...[
            _buildCreditCard(
              context,
              background: _colorForCardIndex(i),
              icon: Icons.credit_card_rounded,
              label: (_savedCards[i].cardType ?? _savedCards[i].bank ?? 'Kartu').toUpperCase(),
              number: _formatMaskedCard(_savedCards[i].maskedCard),
              holder: '',
              expires: '',
              withGlow: i.isOdd,
              onDelete: () => _confirmDeleteCard(_savedCards[i]),
            ),
            const SizedBox(height: 14),
          ],
        ],
        // ── Tambah Kartu Baru Button ────────────────────────────────
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final added = await showAddSavedCardSheet(context);
              if (added == true) _loadSavedCards();
            },
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.outlineVariant,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceContainerHigh,
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: AppColors.outline,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Tambah Kartu Baru',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 14),
                      fontWeight: FontWeight.w600,
                      color: AppColors.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _buildCreditCard(
    BuildContext context, {
    required Color background,
    required IconData icon,
    required String label,
    required String number,
    required String holder,
    required String expires,
    bool withGlow = false,
    VoidCallback? onDelete,
  }) {
    final s = Responsive.scale(context);

    return Container(
      height: 192 * s,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (onDelete != null)
            Positioned(
              right: 8,
              top: 8,
              child: IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.white70, size: 20),
                tooltip: 'Hapus kartu',
              ),
            ),
          if (withGlow)
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.azureSky.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 48,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: Colors.white, size: 20),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 11),
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.8),
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      number,
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 20),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 3.2,
                      ),
                    ),
                    if (holder.isNotEmpty || expires.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (holder.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CARD HOLDER',
                                  style: TextStyle(
                                    fontSize: Responsive.fontSize(context, 9),
                                    color: Colors.white.withValues(alpha: 0.7),
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  holder,
                                  style: TextStyle(
                                    fontSize: Responsive.fontSize(context, 13),
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          if (expires.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'EXPIRES',
                                  style: TextStyle(
                                    fontSize: Responsive.fontSize(context, 9),
                                    color: Colors.white.withValues(alpha: 0.7),
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  expires,
                                  style: TextStyle(
                                    fontSize: Responsive.fontSize(context, 13),
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodsContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              const Divider(
                height: 1,
                indent: 72,
                color: Color(0xFFE5E2E1),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildMethodTile(PaymentMethod m) {
    final svgString = _svgForCode(m.code);

    return InkWell(
      onTap: () => _showMethodSnack(m),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFE5E2E1),
                ),
              ),
              child: Center(
                child: svgString != null
                    ? SvgPicture.string(
                        svgString,
                        width: 40,
                        height: 28,
                        fit: BoxFit.contain,
                      )
                    : Icon(
                        m.isEwallet
                            ? Icons.account_balance_wallet_rounded
                            : Icons.account_balance_rounded,
                        color: AppColors.azureSky,
                        size: 22,
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.name,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 14),
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${m.gateway} • ${m.code}',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 12),
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.outline,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodTileSkeleton extends StatelessWidget {
  const _MethodTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const SkeletonBox(width: 52, height: 40, borderRadius: 10),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(width: 160, height: 14),
                SizedBox(height: 6),
                SkeletonBox(width: 100, height: 12),
              ],
            ),
          ),
          const SkeletonBox(width: 20, height: 20, borderRadius: 10),
        ],
      ),
    );
  }
}
